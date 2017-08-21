import sys
import os
import logging
import datetime
import argparse
from fabric.api import settings, run as fabric_run, put, env
from scotty import utils


logger = logging.getLogger(__name__)


class DataCaching():

    server_no = ""
    server_threads = ""
    memory = ""
    object_size = ""
    client_threats = ""
    interval = ""
    server_memory = ""
    scaling_factor = ""
    duration = ""
    fraction = ""
    connection = ""

    def ssh_to(self, root_path, key_path, remote_server):
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, key_filename="/tmp/" + key_path + "/private.key", user="cloud"):
            fabric_run('mkdir -p ~/benchmark/cs-datacaching')
            put(root_path + '/asset/', '~/benchmark/cs-datacaching/')
            put(root_path + '/benchmark.sh', '~/benchmark/cs-datacaching/')
            fabric_run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
            fabric_run('echo "[+] Installing SNAP ....."')
            fabric_run(
                'sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash')
            fabric_run('sudo apt-get install -y snap-telemetry')
            fabric_run('sudo service snap-telemetry restart')
            fabric_run('sudo mkdir -p /var/log/benchmark')
            fabric_run('sudo chmod 777 /var/log/benchmark/')
            fabric_run(
                'sudo echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n" >> /var/log/benchmark/detail.csv')
            fabric_run("cd ~/benchmark/cs-datacaching/ &&  ./benchmark.sh -a -n " + self.server_no +
                       " -tt " + self.server_threads + " -mm " + self.memory + " -nn " + self.object_size + " -w " + self.client_threats +
                       " -T " + self.interval + " -D " + self.server_memory + " -S " + self.scaling_factor +
                       " -t " + self.duration + " -g " + self.fraction + " -c " +
                       self.connection
                       )

    def metadata(self):

        logger.info("\n       Benchmark configuration")
        logger.info("=========================================\n")
        logger.info("        --------- Servers ---------")
        logger.info(
            "        Number of Server: {}            ".format(self.server_no))
        logger.info("        Server Threads:   {}            ".format(
            self.server_threads))
        logger.info(
            "        dedicated memory: {}            ".format(self.memory))
        logger.info(
            "        Object Size:      {}            ".format(self.object_size))
        logger.info("        --------- Client ----------")
        logger.info("        Client threats:   {}            ".format(
            self.client_threats))
        logger.info(
            "        Interval:         {}            ".format(self.interval))
        logger.info("        Server memory:    {}            ".format(
            self.server_memory))
        logger.info("        Scaling factor:   {}            ".format(
            self.scaling_factor))
        logger.info(
            "        Fraction:         {}            ".format(self.fraction))
        logger.info(
            "        Connections:      {}            ".format(self.connection))
        logger.info(
            "        Duration:         {}            ".format(self.duration))
        logger.info("\n")


def result(context):
    pass


def run(context):

    workload = context.v1.workload
    experiment_helper = utils.ExperimentHelper(context)
    demo_resource = experiment_helper.get_resource(
        workload.resources['csdc_res'])
    dcWorkload = DataCaching()
    dcWorkload.server_no = str(workload.config[
        'params']['server_no'])
    dcWorkload.server_threads = str(workload.config[
        'params']['server_threads'])
    dcWorkload.memory = str(workload.config['params']['memory'])
    dcWorkload.object_size = str(workload.config[
        'params']['object_size'])
    dcWorkload.client_threats = str(workload.config[
        'params']['client_threats'])
    dcWorkload.interval = str(workload.config['params']['interval'])
    dcWorkload.server_memory = str(workload.config[
        'params']['server_memory'])
    dcWorkload.scaling_factor = str(workload.config[
        'params']['scaling_factor'])
    dcWorkload.duration = str(workload.config['params']['duration'])
    dcWorkload.fraction = str(workload.config['params']['fraction'])
    dcWorkload.connection = str(workload.config[
        'params']['connection'])
    root_path = os.path.abspath('') + "/workload/" + workload.name
    dcWorkload.metadata()
    start_time = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

    dcWorkload.ssh_to(
        root_path,
        demo_resource.config['params']['exp_name'],
        demo_resource.endpoint['ip']
    )
    end_time = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

    file = open("/tmp/PostRunInfo", "w")
    file.write("{}\n{}\n{}".format(demo_resource.config['params'][
               'exp_name'], str(start_time), str(end_time)))
    file.close()
