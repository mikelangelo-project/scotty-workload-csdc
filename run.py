import sys
import os
import logging
import argparse
from fabric.api import settings, run, put
from asset.resource_deployment import HeatStack

logger = logging.getLogger(__name__)


def ssh_to(remote_server):

    with settings(host_string=remote_server, key_filename="/tmp/private.key", user="ubuntu"):
        run('mkdir -p ~/benchmark/cs-datacaching')
        put('asset', '~/benchmark/cs-datacaching')
        put('benchmark.sh', '~/benchmark/cs-datacaching')
        run('sudo chmod 750 ~/benchmark/cs-datacaching/benchmark.sh')
        run('echo "[+] Installing SNAP ....."')
        run('sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash')
        run('sudo apt-get install -y snap-telemetry')
        run('sudo service snap-telemetry start')
        run('sudo mkdir -p /var/log/benchmark')
        run('sudo chmod 777 /var/log/benchmark/')
        run('sudo echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n" >> /var/log/benchmark/detail.csv')
        run(
            "cd ~/benchmark/cs-datacaching/ && ./benchmark.sh -a -n " + args.server_no +
            " -tt " + args.server_threads + " -mm " + args.memory + " -nn " + args.object_size + " -w " + args.client_threats +
            " -T " + args.interval + " -D " + args.server_memory + " -S " + args.scaling_factor +
            " -t " + args.duration + " -g " + args.fraction + " -c " + args.connection
        )


def deploy_benchmark(action):
    root_path = os.getcwd()
    config_path = root_path + "/asset/"
    stack = HeatStack(args.name, 2, config_path + "stack.yaml")
    if action == "create":
        metadata()
        stack.create_keypair()
        stack.create()
        print "#"
        logging.info("# Swarm Manager IP address is : " + stack.getManagerIP())
        print "#"
        ssh_to(stack.getManagerIP())
    elif action == "delete":
        stack.delete_keypair()
        stack.delete()
    else:
        logging.warning(
            "The action is not defined. please use create or delete")
        sys.exit()


def metadata():

    logger.info("\n       Benchmark configuration")
    logger.info("=========================================\n")
    logger.info("        --------- Servers ---------")
    logger.info(
        "        Number of Server: {}            ".format(args.server_no))
    logger.info("        Server Threads:   {}            ".format(
        args.server_threads))
    logger.info(
        "        dedicated memory: {}            ".format(args.memory))
    logger.info(
        "        Object Size:      {}            ".format(args.object_size))
    logger.info("        --------- Client ----------")
    logger.info("        Client threats:   {}            ".format(
        args.client_threats))
    logger.info(
        "        Interval:         {}            ".format(args.interval))
    logger.info("        Server memory:    {}            ".format(
        args.server_memory))
    logger.info("        Scaling factor:   {}            ".format(
        args.scaling_factor))
    logger.info(
        "        Fraction:         {}            ".format(args.fraction))
    logger.info(
        "        Connections:      {}            ".format(args.connection))
    logger.info(
        "        Duration:         {}            ".format(args.duration))
    logger.info("\n")


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-N', '--name', help='Benchmark name. default: cs-datacaching', default='cs-datacaching')

    parser.add_argument(
        '-a', '--action', help='Available actions are "create" & "delete"')

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
    output = ""
    key_name = "cs-datacaching"
    if args.action:
        deploy_benchmark(args.action)
    else:
        parser.print_help()
