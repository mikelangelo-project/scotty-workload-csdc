#! /usr/bin/env python
import datetime
import logging
import os

from fabric.api import put, run as fabric_run, settings

from scotty import utils

logger = logging.getLogger(__name__)


class DataCaching(object):
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)

    def upload_benchmark(self, root_path):
        fabric_run(
            '[ -d ~/benchmark/cs-datacaching ] || mkdir -p ~/benchmark/cs-datacaching')
        put(root_path + '/asset/', '~/benchmark/cs-datacaching/')
        put(root_path + '/benchmark.sh', '~/benchmark/cs-datacaching/')
        fabric_run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
        fabric_run('sudo mkdir -p /var/log/benchmark')
        fabric_run('sudo chmod 777 /var/log/benchmark/')
        fabric_run(
            'sudo echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n" >> /var/log/benchmark/detail.csv')

    def install_snap(self):
        fabric_run('echo "[+] Installing SNAP ....."')
        fabric_run(
            'sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash')
        fabric_run('sudo apt-get install -y snap-telemetry')
        fabric_run('sudo service snap-telemetry restart')

    def run_benchmark(self):
        fabric_run("cd ~/benchmark/cs-datacaching/ && ./benchmark.sh -a -n " +
                   self.server_no +
                   " -tt " + self.server_threads +
                   " -mm " + self.memory +
                   " -nn " + self.object_size +
                   " -w " + self.client_threats +
                   " -T " + self.interval +
                   " -D " + self.server_memory +
                   " -S " + self.scaling_factor +
                   " -t " + self.duration +
                   " -g " + self.fraction +
                   " -c " + self.connection)

    def _ssh_to(self, root_path, key_path, remote_server):
        logging.info("# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server,
                      key_filename="/tmp/" + key_path +
                      "/private.key", user="cloud"):
            self.upload_benchmark(root_path)
            self.install_snap()
            self.run_benchmark()

    def metadata(self):
        benchmark_vars = {
            'Number of Server': self.server_no,
            'Server Threads': self.server_threads,
            'Dedicated memory': self.memory,
            'Server memory': self.server_memory,
            'Object Size': self.object_size,
            'Client threats': self.client_threats,
            'Interval': self.interval,
            'Scaling factor': self.scaling_factor,
            'Fraction': self.fraction,
            'Connections': self.connection,
            'Duration': self.duration
        }
        logger.info('Benchmark configuration')
        logger.info('-' * 23)
        for key, value in benchmark_vars.items():
            logger.info('{:17}:  {:1}'.format(key, value))

    def write_benchmark_log(self, experiment_name, workload_name, start_time, end_time):
        file_path = os.path.join("/tmp", experiment_name, workload_name)
        if not os.path.exists(file_path):
            os.makedirs(file_path)
        with open(file_path + "/PostRunInfo.txt", "w") as f:
            f.write("{}\n{}\n{}".format(experiment_name,
                                        str(start_time), str(end_time)))

    def get_current_time(self):
        return datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

    def benchmark_run(self, root_path, experiment_name, workload_name, remote_server):
        start_time = self.get_current_time()
        self.metadata()
        self._ssh_to(root_path, experiment_name, remote_server)
        end_time = self.get_current_time()
        self.write_benchmark_log(
            experiment_name, workload_name, start_time, end_time)


def result(context):
    pass


def run(context):
    workload = context.v1.workload
    workload_params = workload.config['params']
    experiment_helper = utils.ExperimentHelper(context)
    resource = experiment_helper.get_resource(
        workload.resources['resource'])
    resource_param = resource.config['params']
    experiment_name = resource_param['experiment_name']
    endpoint_ip = resource.endpoint['ip']
    root_path = os.path.join(os.path.dirname(__file__))
    benchmark = DataCaching(**workload_params)
    benchmark.benchmark_run(root_path, experiment_name, workload.name, endpoint_ip)
