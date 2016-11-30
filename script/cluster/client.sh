# name: Cluster setup for client  node 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash
#set -x

docker_check () {
	
if which docker >/dev/null;
	 then
		echo -e "\n+++++++++++++++++++++++++++++++"
		echo -e "+ Docker is already installed +"
		echo -e "+++++++++++++++++++++++++++++++\n"
	else
		echo -e "\n-------------------------------"
		echo -e "-   Docker is not installed   -"
		echo -e "-------------------------------\n"
		
		echo -e "\n+++++++++++++++++++++++++++++++"
		echo -e "+   Installing Docker .....   +"
		echo -e "++++++++++++++++++++++++++++++-\n"
		curl -sSL https://get.docker.com/ | sh
		sudo service docker stop
fi

}

docker_daemon=$(sudo netstat -tulpn | grep dockerd | wc -l)
docker_service=$(sudo service docker status | cut -d' ' -f2)
client_ip=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

service_check (){
if  test "${docker_service#*"running"}" != $docker_service
	then
		sudo service docker stop
		sleep 2
		if [ -f /var/lock/docker.pid ]; then
			sudo rm /var/lock/docker.pid
		fi
fi

if [ -n $docker_daemon ];
	then
		sudo pkill dockerd
		sleep 2
		if [ -f /var/lock/docker.pid ]; then
		
		sudo rm /var/lock/docker.pid
		fi
fi
}

client_setup () {

echo -e "\n+++++++++++++++++++++++++++++++" 
echo -e "+  Setting up Swarm Client    +"
echo -e "+++++++++++++++++++++++++++++++\n" 

sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=$client_ip:2376 &
sleep 5 

ps=$(sudo docker ps --filter "name=swarm_client" -a -q)
ru=$(sudo docker ps --filter "name=swarm_client" -q)

if [ -n "$ps" ]
then
        echo -e "[I] Stopping Previous containers\n"
        sudo docker stop $ru
        echo -e "\n"       
        echo -e "[I] Removing Previous containers\n"
        sudo docker rm -f $ps
        echo -e "\n"
fi

sudo docker run -d --name swarm_client swarm join --advertise=$client_ip:2375 consul://10.254.1.106:8500

}

prepare_env () {

echo -e "\n+++++++++++++++++++++++++++++++"
echo -e "+    Preparing Environment    +"
echo -e "+++++++++++++++++++++++++++++++\n"

sudo bash asset/setup_nfs.sh -r client -ns 10.254.1.94 -nd /var/log/benchmark


}

docker_check
service_check
prepare_env
client_setup
