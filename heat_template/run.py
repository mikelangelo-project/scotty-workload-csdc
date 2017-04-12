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
#             H E A T   T E M P L A T E   F U N C T I O N               #
#                 create stack using heat template                      #


def heat( bechmark_name, action, key_name ):
    if action=="create":
        try:
            logging.info("[+] Creating Stack... \n")
            output =subprocess.check_output("heat stack-create -f docker-swarm.yaml "+bechmark_name+" -P key_name="+key_name+" -P number_of_node="+str(number_of_node) ,stderr=subprocess.STDOUT,shell=True)
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
        attempt=10
        i=0
        try:
            remove_keypair()
            logging.info("\n[+] Deleting Stack ...")
            output =subprocess.check_output("heat stack-delete -y "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
            logging.info(output)
            logging.info("\n[!] Deleting ...")
            while i < attempt:
                try:
                    output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
                    i  += 1
                except subprocess.CalledProcessError as e:
                    logging.error(e.output)
                    sys.exit

            logging.info("\n[+] Stack successfully deleted")

        except subprocess.CalledProcessError as e:
            logging.error(e.output)
            sys.exit()

#                                                                       #
#       C R E A T E   P U B L I C   &   P R I V A T E   K E Y           #
#                                                                       #

def create_keypair():
    key = RSA.generate(2048)
    with open("/tmp/private.key", 'w') as content_file:
        chmod("/tmp/private.key", 0600)
        content_file.write(key.exportKey('PEM'))
    pubkey = key.publickey()
    with open("/tmp/public.key", 'w') as content_file:
        content_file.write(pubkey.exportKey('OpenSSH'))

    try:
        logging.info("[+] Creating Keypair... \n")
        output =subprocess.check_output("openstack keypair create --public-key /tmp/public.key "+key_name,stderr=subprocess.STDOUT,shell=True)
        logging.info(output)
    except subprocess.CalledProcessError as e:
        logging.error(e.output)
        sys.exit

#                                                                       #
#       R E M O V E   P U B L I C   &   P R I V A T E   K E Y           #
#                                                                       #

def remove_keypair():
    try:
        logging.info("\n[+] Deleting Keypair ...")
        output =subprocess.check_output("openstack keypair delete "+key_name,stderr=subprocess.STDOUT,shell=True)
        logging.info(output)
    except subprocess.CalledProcessError as e:
        logging.error(e.output)


#                                                                       #
#          I P   O F   D O C K E R   S W A R   M A N A G E R            #
#           get ip of Docker swarm manager from created stack            #
def get_manager_ip(bechmark_name):
    try:
        output =subprocess.check_output("heat stack-show "+bechmark_name,stderr=subprocess.STDOUT,shell=True)
        match = re.search(r'(?:\d{1,3}\.){3}\d{1,3}', output)
        get_manager_ip.ip = match.group()
    except subprocess.CalledProcessError as e:
        logging.error(e.output)
        sys.exit

#                                                                       #
#                  S S H  T O   D O C K E R   S W A R M                 #
#                                                                       #

def ssh_to(remote_server):
    with settings(host_string=remote_server,key_filename="/tmp/private.key", user = "ubuntu"):
        run ("cd /usr/src/cs-benchmark && ./benchmark.sh -a -n "+ args.server_no+
        " -tt "+args.server_threads+" -mm "+args.memory +" -nn "+args.object_size +" -w "+args.client_threats +
        " -T "+args.interval +" -D "+args.server_memory +" -S "+args.scaling_factor+" -t "+args.duration +" -g "+args.fraction +" -c "+args.connection)

#                                                                       #
#                      R U N   B E C H N M A R K                        #
#                                                                       #

def run_benchmark():
    metadata()
    create_keypair()
    heat(args.name,"create",key_name)
    get_manager_ip(args.name)
    print "#"
    logging.info("# Swarm Manager IP address is : "+get_manager_ip.ip)
    print "#"
    ssh_to(get_manager_ip.ip)

#                                                                       #
#                    R E M O V E   B E N C H M A R K                    #
#                                                                       #
def remove_benchmark():
    heat(args.name,"delete", None)

#                                                                       #
#                M E T A D T A   I N F O R M A T I O N                  #
#                                                                       #

def metadata():
        #
        #    GET STACK INFORMATION
        #
        flavors={"Swarm Key Value Store":"","Swarm Manager":"","Swarm Client":""}
        stream = open("docker-swarm.yaml", "r")
        docs = yaml.load_all(stream)
        print("\n          Stack configuration")
        print("=========================================\n")
        try:
            for data in docs:
                flavors["Swarm Key Value Store"]=data['parameters']['swarm_keyvaluestore_flv']['default']
                flavors["Swarm Manager"]=data['parameters']['swarm_manager_flv']['default']
                flavors["Swarm Client"]=data['parameters']['swarm_workers_flv']['default']
                print("Total Number of VMs:       {}".format(data['parameters']['number_of_node']['default']+2))
                print("Number of worker VMs:      {}".format(data['parameters']['number_of_node']['default']))
                print("Image ID:                  {}".format(data['parameters']['image_id']['default']))

        except yaml.YAMLError as exc:
            print(exc)

        #
        #    GET HOST INFORMATION
        #
        print("Flavors:")
        for key,value in flavors.items():
            res=subprocess.Popen("openstack flavor show --format json "+value,stdout=subprocess.PIPE,shell=True)
            data=res.stdout.read()
            print("\t{}: {}\n\t[MEMORY: {} CPU: {} DISK: {}]\n".format(key,value,json.loads(data)['ram'],json.loads(data)['vcpus'],json.loads(data)['disk']))
        #
        #    GET Benchmark INFORMATION
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




#                                                                       #
#                               M A I N                                 #
#                                                                       #

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-N', '--name',help='Benchmark name. default: cs-datacaching', default='cs-datacaching')

    parser.add_argument('-a', '--auto',help='running whole benchmark and setup automatically', action='store_true' )
    parser.add_argument('-R', '--remove_all',help='stop and remove all servers & client', action='store_true' )

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
    #Number of Docker swarm clients node is equal to number of servers node
    number_of_node=2



    if args.auto & args.remove_all :
        print "-a (--auto) and -R (--remove_all) can not be used at the same time"
        exit
    elif args.auto:
        run_benchmark()
    elif args.remove_all:
        remove_benchmark()
    else:
        parser.print_help()
