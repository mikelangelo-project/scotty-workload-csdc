# name: Cluster setup for client  node 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash
set -x

docker_check () {
	
if which docker >/dev/null;
	 then
		echo "\n+++++++++++++++++++++++++++++++"
		echo "+ Docker is already installed +"
		echo "+++++++++++++++++++++++++++++++\n"
	else
		echo "\n-------------------------------"
		echo "-   Docker is not installed   -"
		echo "-------------------------------\n"
		
		echo "\n+++++++++++++++++++++++++++++++"
		echo "+   Installing Docker .....   +"
		echo "++++++++++++++++++++++++++++++-\n"
		yum update
		curl -sSL https://get.docker.com/ | sh
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

echo "\n+++++++++++++++++++++++++++++++" 
echo "+  Setting up Swarm Client    +"
echo "+++++++++++++++++++++++++++++++\n" 

sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=$client_ip:2376 &
sleep 5 

ps=$(sudo docker ps --filter "name=swarm_client" -a -q)
ru=$(sudo docker ps --filter "name=swarm_client" -q)

if [ -n "$ps" ]
then
        echo "[I] Stopping Previous containers\n"
        sudo docker stop $ru
        echo "\n"       
        echo "[I] Removing Previous containers\n"
        sudo docker rm -f $ps
        echo "\n"
fi

sudo docker run -d --name swarm_client swarm join --advertise=$client_ip:2375 consul://10.254.1.106:8500

}

prepare_env () {

echo "\n+++++++++++++++++++++++++++++++"
echo "+    Preparing Environment    +"
echo "+++++++++++++++++++++++++++++++\n"

sudo mkdir /var/log/benchmark
sudo bash asset/setup_nfs.sh -r client -ns 10.254.1.104 -nd /var/log/benchmark
sudo touch /var/log/benchmark/detail.csv


}

docker_check
service_check
client_setup
prepare_env
