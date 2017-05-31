import json,sys
import re
import sys
import argparse
import subprocess
from Crypto.PublicKey import RSA


class Heat_stack(object):

    #                                                                       #
    #                          I N I T I A L I Z E                          #
    #                                                                       #

    def __init__(self, stack_name, number_of_node):
        self.stack_name = stack_name
        self.key_name = stack_name
        self.number_of_node = number_of_node
        self.manager_ip = ""


    #                                                                       #
    #       C R E A T E   P U B L I C   &   P R I V A T E   K E Y S         #
    #                                                                       #

    def create_keypair(self):
        key = RSA.generate(2048)
        with open("/tmp/private.key", 'w') as content_file:
            chmod("/tmp/private.key", 0600)
            content_file.write(key.exportKey('PEM'))
        pubkey = key.publickey()
        with open("/tmp/public.key", 'w') as content_file:
            content_file.write(pubkey.exportKey('OpenSSH'))

        try:
            print("[+] Creating Keypair... \n")
            output =subprocess.check_output("openstack keypair create --public-key /tmp/public.key "+self.key_name,stderr=subprocess.STDOUT,shell=True)
            print(output)
        except subprocess.CalledProcessError as e:
            print(e.output)
            sys.exit

    #                                                                       #
    #       R E M O V E   P U B L I C   &   P R I V A T E   K E Y S         #
    #                                                                       #

    def delete_keypair(self):
        try:
            print("\n[+] Deleting Keypair ...")
            output = subprocess.check_output("openstack keypair delete "+self.key_name, stderr=subprocess.STDOUT, shell=True)
            print(output)
        except subprocess.CalledProcessError as e:
            print(e.output)


    #                                                                       #
    #                        C R E A T E   S T A C K                        #
    #                                                                       #

    def create(self):
        self.create_keypair()
        try:
            print("[+] Creating Stack... \n")
            output =subprocess.check_output("openstack stack create --template heat/stack.yaml {} --parameter key_name={} --parameter number_of_node={}".format(self.stack_name,self.key_name,str(self.number_of_node)) ,stderr=subprocess.STDOUT,shell=True)
            print(output)
            print("\n[!] Creating stack takes few minutes")
            while True:
                output =subprocess.Popen("openstack stack show {} --format json".format(self.stack_name),stdout=subprocess.PIPE,shell=True)
                data=json.loads(output.stdout.read())
                result=data['stack_status']
                if "COMPLETE" in result:
                    print("[+] Stack CREATE completed successfully ")
                    self.manager_ip = data['outputs'][0]['output_value']
                    break

                if "FAILED" in result:
                    print("[X] Stack CREATE FAILED\n[X]Check stack logs")
                    sys.exit(0)
        except subprocess.CalledProcessError as e:
            print(e.output)
            sys.exit()

        return self.manager_ip


    #                                                                       #
    #                         D E L E T E    S T A C K                      #
    #                                                                       #
    def delete(self):
        self.delete_keypair()
        attempt=10
        i=0
        try:
            print("\n[+] Deleting Stack ...")
            output =subprocess.check_output("openstack stack delete -y {}".format(self.stack_name),stderr=subprocess.STDOUT,shell=True)
            print(output)
            while i < attempt:
                try:
                    output =subprocess.check_output("openstack stack show {} --format json".format(self.stack_name),stderr=subprocess.STDOUT,shell=True)
                    i  += 1
                except subprocess.CalledProcessError as e:
                    print(e.output)
                    sys.exit()

            print("\n[+] Stack successfully deleted")
        except subprocess.CalledProcessError as e:
            print(e.output)
            sys.exit()



#                                                                       #
#                               M A I N                                 #
#                                                                       #

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--name',help='Benchmark name. default: stack', default='stack')
    parser.add_argument('-a', '--action',help='Name of the action. Options: {"create", "delete"}')
    parser.add_argument('-k', '--keyname',help='Keypair name')
    parser.add_argument('-w', '--nodes',help='Number of Swarm worker nodes')
    args = parser.parse_args()

    stack = Heat_stack(args.name, args.nodes, args.keyname)

    if args.action:
        method = getattr(stack, args.action)
        method()
    else:
        parser.print_help()

