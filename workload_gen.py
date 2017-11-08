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

    def ssh_to_endpoint(self, root_path, remote_server, private_key, user):
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, key_filename=private_key, user=user):
            put(root_path + '/benchmark.sh', '~/benchmark/cs-datacaching/')
            fabric_run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
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
    params = workload.config['params']
    experiment_helper = utils.ExperimentHelper(context)
    resource = experiment_helper.get_resource(
        workload.resources['resource'])
    dc_workload = DataCaching(**params)
    root_path = os.path.join(os.path.dirname(__file__))
    dc_workload.metadata()
    start_time = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    dc_workload.ssh_to_endpoint(
        root_path,
        resource.endpoint['swarm_manager']['ip'],
        resource.endpoint['swarm_manager']['private_key'],
        resource.endpoint['swarm_manager']['user']
    )
    end_time = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    result_path = os.path.join(
        '/tmp/', resource.config['params']['experiment_name'], workload.name)
    if not os.path.exists(result_path):
        os.makedirs(result_path)

    file = open(result_path + "/PostRunInfo.txt", "w")
    file.write("{}\n{}\n{}".format(resource.config['params'][
               'experiment_name'], str(start_time), str(end_time)))
    file.close()
