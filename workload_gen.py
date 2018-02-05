#! /usr/bin/env python
import datetime
import logging
import os

from fabric.api import put, hide, settings
from fabric.api import run as fb_run

from scotty import utils


logger = logging.getLogger(__name__)


def reduce_logging():
    reduce_loggers = {
        'keystoneauth.identity.v2',
        'keystoneauth.identity.v2.base',
        'keystoneauth.session',
        'urllib3.connectionpool',
        'stevedore.extension',
        'novaclient.v2.client',
        'paramiko.transport'
    }
    for logger in reduce_loggers:
        logging.getLogger(logger).setLevel(logging.WARNING)


reduce_logging()


class DataCachingWorkload(object):

    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)

    def push_files(self, root_path, remote_server, private_key, user):
        logging.info("Pushing files to Manager : ")
        with hide('output'), settings(host_string=remote_server,
                      key_filename=private_key, user=user):
            put(root_path + '/benchmark.sh', '~/benchmark/cs-datacaching/')
            put(root_path + '/warmup.sh', '~/benchmark/cs-datacaching/')
            fb_run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
            fb_run('sudo chmod 750 ~/benchmark/cs-datacaching/warmup.sh')

    def warmp_up(self, root_path, remote_server, private_key, user):
        logging.info("Warming up the Server : " + remote_server)
        with hide('output'), settings(host_string=remote_server,
                      key_filename=private_key, user=user):
            put(root_path + '/benchmark.sh', '~/benchmark/cs-datacaching/')
            fb_run("cd ~/benchmark/cs-datacaching/ && ./warmup.sh -a -n " +
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

    def run_benchmark(self, root_path, remote_server, private_key, user):
        logging.info("Running Benchmark on : " + remote_server)
        with hide('output'), settings(host_string=remote_server,
                      key_filename=private_key, user=user):
            fb_run("cd ~/benchmark/cs-datacaching/ && ./benchmark.sh " + self.duration)

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
    def get_current_time(self):
            return datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

    def write_benchmark_log(self, experiment_name, workload_name, start_time, end_time):
        file_path = os.path.join("/tmp", experiment_name, workload_name)
        if not os.path.exists(file_path):
            os.makedirs(file_path)
        with open(file_path + "/PostRunInfo.txt", "w") as f:
            f.write("{}\n{}\n{}".format(experiment_name,
                                        str(start_time), str(end_time)))


def result(context):
    pass


def run(context):
    workload = context.v1.workload
    params = workload.config['params']
    experiment_helper = utils.ExperimentHelper(context)
    resource = experiment_helper.get_resource(
        workload.resources['resource'])
    experiment_name = resource.config['params']['experiment_name']
    workload_utils = utils.WorkloadUtils(context)
    workload_path = workload_utils.component_data_path
    csdc_workload = DataCachingWorkload(**params)
    root_path = os.path.join(os.path.dirname(__file__))
    csdc_workload.metadata()
    ssh_access = [
        root_path,
        resource.endpoint['swarm_manager']['ip'],
        resource.endpoint['swarm_manager']['private_key'],
        resource.endpoint['swarm_manager']['user']
    ]
    start_time = csdc_workload.get_current_time()
    csdc_workload.push_files(*ssh_access)
    csdc_workload.warmp_up(*ssh_access)
    wait_file_name = os.path.join(workload_path, params['warmup_file'])
    experiment_utils = utils.ExperimentUtils(context)
    with experiment_utils.open_file(params['warmup_file'], 'w') as f:
        f.write('Server is warmup\n')
    csdc_workload.run_benchmark(*ssh_access)
    end_time = csdc_workload.get_current_time()
    csdc_workload.write_benchmark_log(
        experiment_name, workload.name, str(start_time), str(end_time))


def clean(context):
    experiment_utils = utils.ExperimentUtils(context)
    workload = context.v1.workload
    params = workload.config['params']
    warmup_file = params.get('warmup_file', 'warm.up')
    logger.info('Remove warmup file: {}'.format(warmup_file))
    experiment_utils.remove_file(warmup_file)
