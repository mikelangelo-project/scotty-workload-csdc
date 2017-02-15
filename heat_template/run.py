import re
import sys
import argparse
import subprocess
from fabric.api import *

def heat( bechmark_name ):
    output =subprocess.check_output("heat stack-create -f swarm.yaml  "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
    print output
    print "\n[!] Creating stack takes few mintues"
    while True:
        output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
        match = re.search(r'(?<=stack_status).*', output)
        result=match.group()
        if "COMPLETE" in result:
            print "[+] Stack CREATE completed successfully "
            break

        if "FAILED" in result:
            print "[X] Stack CREATE FAILED\n[X]Check stack logs"
            sys.exit(0)


def get_manager_ip(bechmark_name):
    output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
    match = re.search(r'(?:\d{1,3}\.){3}\d{1,3}', output)
    get_manager_ip.ip = match.group()

def deploy(remote_server):
    with settings(host_string=remote_server, user = "ubuntu"):
        run ('cd /usr/src/cs-benchmark && ./benchmark.sh -a')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-N', '--name',help='Benchmark name. default: cs-datacaching', default='cs-datacaching')

    parser.add_argument('-a', '--auto',help='running whole benchmark and setup automatically', default='cs-datacaching')
    parser.add_argument('-R', '--remove_all',help='stop and remove all servers & client', default='cs-datacaching')

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
    heat(args.name)
    get_manager_ip(args.name)
    print "#"
    print "# Swarm Manager IP address is : "+get_manager_ip.ip
    print "#"
    deploy(get_manager_ip.ip)
