import re
import sys
import logging
import argparse
import subprocess
from fabric.api import *

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                    datefmt='%m-%d %H:%M',
                    filename='/tmp/myapp.log',
                    filemode='w')
console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
formatter = logging.Formatter('%(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)

def heat( bechmark_name, action ):
    output=""
    if action=="create":
        try:
            output =subprocess.check_output("heat stack-create -f docker-swarm.yaml  "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
            logging.info(output)
            logging.info("\n[!] Creating stack takes few mintues")
            while True:
                output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
                match = re.search(r'(?<=stack_status).*', output)
                result=match.group()
                if "COMPLETE" in result:
                    logging.info("[+] Stack CREATE completed successfully ")
                    break

                if "FAILED" in result:
                    logging.error("[X] Stack CREATE FAILED\n[X]Check stack logs")
                    sys.exit(0)
        except subprocess.CalledProcessError as e:
            logging.error(e.output)
            sys.exit()



    if action== "delete":
        try:
            output =subprocess.check_output("heat stack-delete -y "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
            logging.info(output)
            logging.info("\n[!] Deleting ...")
            while True:
                output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
                match = re.search(r'(?<=stack_status).*', output)
                result=match.group()
                if "COMPLETE" in result:
                    logging.info("[+] Stack DELETE completed successfully ")
                    break

                if "FAILED" in result:
                    logging.error("[X] Stack CREATE FAILED\n[X]Check stack logs")
                    sys.exit(0)
        except subprocess.CalledProcessError as e:
            logging.error(e.output)
            sys.exit()




def get_manager_ip(bechmark_name):
    output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
    match = re.search(r'(?:\d{1,3}\.){3}\d{1,3}', output)
    get_manager_ip.ip = match.group()

def deploy(remote_server):
    with settings(host_string=remote_server, user = "ubuntu"):
        run ('cd /usr/src/cs-benchmark && ./benchmark.sh -a')

def run_benchmark():
    heat(args.name,"create")
    get_manager_ip(args.name)
    print "#"
    logging.info("# Swarm Manager IP address is : "+get_manager_ip.ip)
    print "#"
    deploy(get_manager_ip.ip)

def remove_benchmark():
    heat(args.name,"delete")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-N', '--name',help='Benchmark name. default: cs-datacaching', default='cs-datacaching')

    parser.add_argument('-a', '--auto',help='running whole benchmark and setup automatically', action='store_true' )
    parser.add_argument('-R', '--remove_all',help='stop and remove all servers & client', action='store_true' )

    parser.add_argument('-n', '--server-no',help='number of server (default: 4)', default=4)
    parser.add_argument('-tt', '--server-threads',help='number of threads of server (default: 4)', default=4)
    parser.add_argument('-mm', '--memory',help='dedicated memory (default: 4096)', default=4096)
    parser.add_argument('-nn', '--object-size',help='object size (default: 550)', default=550)
    parser.add_argument('-w', '--client-threats',help='number of client threads (default: 4)', default=4)
    parser.add_argument('-T', '--interval',help='interval between stats printing (default: 1)', default=1)
    parser.add_argument('-D', '--server-memory',help='size of main memory available to each memcached server in MB (default: 4096)', default=4096)
    parser.add_argument('-S', '--scaling-factor',help='dataset scaling factor (default: 30)', default=2)
    parser.add_argument('-t', '--duration',help='runtime of loadtesting in seconds (default: run forever)')
    parser.add_argument('-g', '--fraction',help='fraction of requests that are gets (default: 0.8)', default=0.8)
    parser.add_argument('-c', '--connection',help='total TCP connections (default: 200)', default=200)


    args = parser.parse_args()
    if args.auto & args.remove_all :
        print "-a (--auto) and -R (--remove_all) can not be used at the same time"
        exit
    elif args.auto:
        run_benchmark()
    elif args.remove_all:
        remove_benchmark()
    else:
        parser.print_help()
