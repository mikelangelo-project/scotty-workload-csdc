import yaml
import json,sys
import re
import sys
import logging
import argparse
import subprocess
from os import chmod
from fabric.api import *
from Crypto.PublicKey import RSA
from resource_deployment import Heat_stack




#                                                                       #
#                  S E T T I N G   U P   L O G G I N G                  #
#                                                                       #

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                    datefmt='%m-%d %H:%M',
                    filename='/tmp/cs-datacahing.log',
                    filemode='w')


console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
formatter = logging.Formatter('%(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)



#                                                                       #
#                  S S H  T O   S W A R M   M A N A G E R               #
#                                                                       #


def ssh_to(remote_server):
    with settings(host_string=remote_server,key_filename="/tmp/private.key", user = "ubuntu"):
        run ('mkdir -p ~/benchmark/cs-datacaching')
        put ('asset', '~/benchmark/cs-datacaching')
        put ('benchmark.sh', '~/benchmark/cs-datacaching')
        run ('sudo chmod 750', '~/benchmark/cs-datacaching/benchmark.sh')
        run ('echo "[+] Installing SNAP ....."')
        run ('sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash')
        run ('sudo apt-get install -y snap-telemetry')
        run ('sudo service snap-telemetry start')
        run ('sudo mkdir -p /var/log/benchmark')
        run ('sudo chmod 777 /var/log/benchmark/')
        run ('sudo echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n" >> /var/log/benchmark/detail.csv')
        run ("cd ~/benchmark/cs-datacaching/ && ./benchmark.sh -a -n "+ args.server_no+
        " -tt "+args.server_threads+" -mm "+args.memory +" -nn "+args.object_size +" -w "+args.client_threats +
        " -T "+args.interval +" -D "+args.server_memory +" -S "+args.scaling_factor+" -t "+args.duration +" -g "+args.fraction +" -c "+args.connection)

#                                                                       #
#                      R U N   B E C H N M A R K                        #
#                                                                       #

def benchmark(action):
    stack = Heat_stack(args.name, 2)
    if action == "create":
        metadata()
        stack.create_keypair()
        stack.create()
        print "#"
        logging.info("# Swarm Manager IP address is : "+stack.manager_ip)
        print "#"
        ssh_to(stack.manager_ip)
    elif action == "delete":
        stack.delete_keypair()
        stack.delete()




#                                                                       #
#                M E T A D T A   I N F O R M A T I O N                  #
#                                                                       #

def metadata():
        #
        #    G E T   B E N C H M A R K   M E D A T A D A
        #

        print("\n       Benchmark configuration")
        print("=========================================\n")
        print("        --------- Servers ---------")
        print("        Number of Server: {}            ".format(args.server_no))
        print("        Server Threads:   {}            ".format(args.server_threads))
        print("        dedicated memory: {}            ".format(args.memory))
        print("        Object Size:      {}            ".format(args.object_size))
        print("        --------- Client ----------")
        print("        Client threats:   {}            ".format(args.client_threats))
        print("        Interval:         {}            ".format(args.interval))
        print("        Server memory:    {}            ".format(args.server_memory))
        print("        Scaling factor:   {}            ".format(args.scaling_factor))
        print("        Fraction:         {}            ".format(args.fraction))
        print("        Connections:      {}            ".format(args.connection))
        print("        Duration:         {}            ".format(args.duration))
        print("\n")



#                                                                       #
#                               M A I N                                 #
#                                                                       #

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-N', '--name',help='Benchmark name. default: cs-datacaching', default='cs-datacaching')

    parser.add_argument('-a', '--action',help='Available actions are "create" & "delete"    ' )

    parser.add_argument('-n', '--server_no',help='number of server (default: 4)', default="4")
    parser.add_argument('-tt', '--server_threads',help='number of threads of server (default: 4)', default="4")
    parser.add_argument('-mm', '--memory',help='dedicated memory (default: 4096)', default="4096")
    parser.add_argument('-nn', '--object_size',help='object size (default: 550)', default="550")
    parser.add_argument('-w', '--client_threats',help='number of client threads (default: 4)', default="4")
    parser.add_argument('-T', '--interval',help='interval between stats printing (default: 1)', default="1")
    parser.add_argument('-D', '--server_memory',help='size of main memory available to each memcached server in MB (default: 4096)', default="4096")
    parser.add_argument('-S', '--scaling_factor',help='dataset scaling factor (default: 30)', default="2")
    parser.add_argument('-t', '--duration',help='runtime of loadtesting in seconds (default: run forever)', default="0")
    parser.add_argument('-g', '--fraction',help='fraction of requests that are gets (default: 0.8)', default="0.8")
    parser.add_argument('-c', '--connection',help='total TCP connections (default: 200)', default="200")

    args = parser.parse_args()




#                                                                       #
#          D E F I N E   P R I M A R Y   V A R I A B L E S              #
#                                                                       #

    output=""
    key_name = "cs-datacaching"



    if args.action :
        benchmark(args.action)
    else:
        parser.print_help()
