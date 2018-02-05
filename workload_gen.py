#! /usr/bin/env python
import datetime
import logging
import os

from fabric.api import put, settings
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
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, warn_only=True,
                      key_filename=private_key, user=user):
            put(root_path + '/benchmark.sh', '~/benchmark/cs-datacaching/')
            put(root_path + '/warmup.sh', '~/benchmark/cs-datacaching/')
            fb_run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
            fb_run('sudo chmod 750 ~/benchmark/cs-datacaching/warmup.sh')

    def warmp_up(self, root_path, remote_server, private_key, user):
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, warn_only=True,
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
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, warn_only=True,
                      key_filename=private_key, user=user):
            fb_run("cd ~/benchmark/cs-datacaching/ && ./benchmark.sh " + self.duration )

    def metadata(self):

        logger.info("\n Benchmark Configuration")
        logger.info("=========================\n")
        logger.info(" --------- Servers -----")
        logger.info(" Number of Server: {} ".format(self.server_no))
        logger.info(" Server Threads:   {} ".format(self.server_threads))
        logger.info(" dedicated memory: {} ".format(self.memory))
        logger.info(" Object Size:      {} ".format(self.object_size))
        logger.info(" --------- Client ------")
        logger.info(" Client threats:   {} ".format(self.client_threats))
        logger.info(" Interval:         {} ".format(self.interval))
        logger.info(" Server memory:    {} ".format(self.server_memory))
        logger.info(" Scaling factor:   {} ".format(self.scaling_factor))
        logger.info(" Fraction:         {} ".format(self.fraction))
        logger.info(" Connections:      {} ".format(self.connection))
        logger.info(" Duration:         {} ".format(self.duration))
        logger.info("\n")


def result(context):
    pass


def run(context):
    workload = context.v1.workload
    params = workload.config['params']
    experiment_helper = utils.ExperimentHelper(context)
    resource = experiment_helper.get_resource(
        workload.resources['resource'])
    csdc_workload = DataCachingWorkload(**params)
    root_path = os.path.join(os.path.dirname(__file__))
    csdc_workload.metadata()
    start_time = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    ssh_access = [
        root_path,
        resource.endpoint['swarm_manager']['ip'],
        resource.endpoint['swarm_manager']['private_key'],
        resource.endpoint['swarm_manager']['user']
    ]
    csdc_workload.push_files(*ssh_access)
    csdc_workload.warmp_up(*ssh_access)
    experiment_utils = utils.ExperimentUtils(context)
    warmup_file = params.get('warmup_file', 'warm.up')
    logger.info('Write warmup file: {}'.format(warmup_file))
    with experiment_utils.open_file(warmup_file, 'w') as f:
        f.write('Server is warmup\n')
    csdc_workload.run_benchmark(*ssh_access)
    end_time = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    result_path = os.path.join(
        '/tmp/', resource.config['params']['experiment_name'], workload.name)
    if not os.path.exists(result_path):
        os.makedirs(result_path)

    file = open(result_path + "/PostRunInfo.txt", "w")
    file.write("{}\n{}\n{}".format(resource.config['params'][
               'experiment_name'], str(start_time), str(end_time)))
    file.close()


def clean(context):
    experiment_utils = utils.ExperimentUtils(context)
    workload = context.v1.workload
    params = workload.config['params']
    warmup_file = params.get('warmup_file', 'warm.up')
    logger.info('Remove warmup file: {}'.format(warmup_file))
    experiment_utils.remove_file(warmup_file)
