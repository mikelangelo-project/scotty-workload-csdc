import sys
import os
import logging
import argparse
from fabric.api import settings, run, put
from asset.resource_deployment import HeatStack

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DataCaching():

    server_no = context.v1.workload_config['params']['server_no']
    server_threads = context.v1.workload_config['params']['server_threads']
    memory = context.v1.workload_config['params']['memory']
    object_size = context.v1.workload_config['params']['object_size']
    client_threats = context.v1.workload_config['params']['client_threats']
    interval = context.v1.workload_config['params']['interval']
    server_memory = context.v1.workload_config['params']['server_memory']
    scaling_factor = context.v1.workload_config['params']['scaling_factor']
    duration = context.v1.workload_config['params']['duration']
    fraction = context.v1.workload_config['params']['fraction']
    connection = context.v1.workload_config['params']['connection']

    def ssh_to(self, remote_server):
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, key_filename="/tmp/private.key", user="cloud"):
            run('mkdir -p ~/benchmark/cs-datacaching')
            put('asset', '~/benchmark/cs-datacaching')
            put('benchmark.sh', '~/benchmark/cs-datacaching')
            run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
            run('echo "[+] Installing SNAP ....."')
            run('sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash')
            run('sudo apt-get install -y snap-telemetry')
            run('sudo service snap-telemetry restart')
            run('sudo mkdir -p /var/log/benchmark')
            run('sudo chmod 777 /var/log/benchmark/')
            run('sudo echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n" >> /var/log/benchmark/detail.csv')
            run(
                "cd ~/benchmark/cs-datacaching/ && ./benchmark.sh -a -n " + server_no +
                " -tt " + server_threads + " -mm " + memory + " -nn " + object_size + " -w " + client_threats +
                " -T " + interval + " -D " + server_memory + " -S " + scaling_factor +
                " -t " + duration + " -g " + fraction + " -c " + connection
            )

    def deploy_benchmark(self, action):
        root_path = os.getcwd()
        config_path = root_path + "/asset/"
        stack = HeatStack(name, 1, config_path + "stack.yaml")
        if action == "create":
            self.metadata()
            stack.create()
            self.ssh_to(stack.getManagerIP())
        elif action == "delete":
            stack.delete()
        else:
            logging.warning(
                "The action is not defined. please use create, delete")
            sys.exit()

    def metadata(self):

        logger.info("\n       Benchmark configuration")
        logger.info("=========================================\n")
        logger.info("        --------- Servers ---------")
        logger.info(
            "        Number of Server: {}            ".format(server_no))
        logger.info("        Server Threads:   {}            ".format(
            server_threads))
        logger.info(
            "        dedicated memory: {}            ".format(memory))
        logger.info(
            "        Object Size:      {}            ".format(object_size))
        logger.info("        --------- Client ----------")
        logger.info("        Client threats:   {}            ".format(
            client_threats))
        logger.info(
            "        Interval:         {}            ".format(interval))
        logger.info("        Server memory:    {}            ".format(
            server_memory))
        logger.info("        Scaling factor:   {}            ".format(
            scaling_factor))
        logger.info(
            "        Fraction:         {}            ".format(fraction))
        logger.info(
            "        Connections:      {}            ".format(connection))
        logger.info(
            "        Duration:         {}            ".format(duration))
        logger.info("\n")


def run(context):
    dcWorkload = DataCaching()
    key_name = "cs-datacaching"
    action = 'create'
    dcWorkload.deploy_benchmark(action)
