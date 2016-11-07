# name: Automated Creation of Docker Discovery 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


docker_check () {
	
if which docker >/dev/null;
	 then
		echo "\n+++++++++++++++++++++++++++++++"
		echo "+ Docker is already installed +"
		echo "+++++++++++++++++++++++++++++++\n"
	else
		echo -e "Installing Docker\n ++++++++++++ "
		yum update
		curl -sSL https://get.docker.com/ | sh
fi

}

docker_daemon=$(sudo netstat -tulpn | grep dockerd | wc -l)
docker_service=$(sudo service docker status | cut -d' ' -f2)
manager_ip=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

service_check (){
if  test "${docker_service#*"running"}" != $docker_service
	then
		sudo service docker stop
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

manager_setup () {

echo "\n+++++++++++++++++++++++++++++++" 
echo "+  Setting up Swarm manager  +"
echo "+++++++++++++++++++++++++++++++\n" 
sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=$manager_ip:2376 &
sleep 5 

ps=$(sudo docker ps --filter "name=swarm_manager" -a -q)
ru=$(sudo docker ps --filter "name=swarm_manager" -a -q)

if [ -n "$ps" ]
then
        echo "[I] Stopping Previous containers\n"
        sudo docker stop  $(docker ps --filter "name=swarm_manager" -a -q)
        echo "\n"       
        echo "[I] Removing Previous containers\n"
        sudo docker rm -f $(docker ps --filter "name=swarm_manager" -a -q)
        echo "\n"
fi

sudo docker run -d --name swarm_manager -p 4000:4000 swarm manage -H :4000 --replication --advertise $manager_ip:4000 consul://10.254.1.106:8500
echo "[+] Client Swarm manager is ready\n"

sudo docker run -d --name swarm_manager_node swarm join --advertise=$manager:2375 consul://10.254.1.106:8500
echo "[+] Swarm manager joined as node\n"
}


docker_check
service_check
manager_setup
