import sys
import os
import logging
import argparse
from fabric.api import settings, run as fabric_run, put, env
from asset.resource_deployment import HeatStack

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

    def ssh_to(self, root_path, remote_server):
        logging.info("\n# Swarm Manager IP address is : " + remote_server)
        with settings(host_string=remote_server, key_filename="/tmp/private.key", user="cloud"):
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

    def deploy_benchmark(self, name, action):
        root_path = os.getcwd()
        config_path = root_path + "/asset/"
        stack = HeatStack(name, 1, config_path + "stack.yaml")
        if action == "create":
            self.metadata()
            stack.create()
            self.ssh_to(root_path, stack.getManagerIP())
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


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-N', '--name', help='Benchmark name. default: cs-datacaching', default='csdcWorkload')

    parser.add_argument(
        '-a', '--action', help='Available actions are "create, delete" ')

    parser.add_argument('-n', '--server_no',
                        help='number of server (default: 4)', default="4")
    parser.add_argument('-tt', '--server_threads',
                        help='number of threads of server (default: 4)', default="4")
    parser.add_argument(
        '-mm', '--memory', help='dedicated memory (default: 4096)', default="4096")
    parser.add_argument('-nn', '--object_size',
                        help='object size (default: 550)', default="550")
    parser.add_argument('-w', '--client_threats',
                        help='number of client threads (default: 4)', default="4")
    parser.add_argument(
        '-T', '--interval', help='interval between stats printing (default: 1)', default="1")
    parser.add_argument('-D', '--server_memory',
                        help='size of main memory available to each memcached server in MB (default: 4096)', default="4096")
    parser.add_argument('-S', '--scaling_factor',
                        help='dataset scaling factor (default: 30)', default="2")
    parser.add_argument(
        '-t', '--duration', help='runtime of loadtesting in seconds (default: run forever)', default="0")
    parser.add_argument(
        '-g', '--fraction', help='fraction of requests that are gets (default: 0.8)', default="0.8")
    parser.add_argument(
        '-c', '--connection', help='total TCP connections (default: 200)', default="200")

    args = parser.parse_args()
    dcWorkload = DataCaching()
    dcWorkload.server_no = args.server_no
    dcWorkload.server_threads = args.server_threads
    dcWorkload.memory = args.memory
    dcWorkload.object_size = args.object_size
    dcWorkload.client_threats = args.client_threats
    dcWorkload.interval = args.interval
    dcWorkload.server_memory = args.server_memory
    dcWorkload.scaling_factor = args.scaling_factor
    dcWorkload.duration = args.duration
    dcWorkload.fraction = args.fraction
    dcWorkload.connection = args.connection

    key_name = args.name
    action = args.action
    dcWorkload.deploy_benchmark(key_name, action)
