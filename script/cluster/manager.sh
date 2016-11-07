# name: Automated Creation of Docker Discovery 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


docker_check () {
	
if which docker >/dev/null;
	 then
		echo "\n+++++++++++++++++++++++++++"
		echo "Docker is already installed"
		echo "+++++++++++++++++++++++++++\n"
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

if [ -n $docker_daemon ]; then
	sudo pkill dockerd
	if [ -f /var/lock/docker.pid ]; then
		sudo rm /var/lock/docker.pid
	fi
fi
}

manager_setup () {
sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=$manager_ip:2376 &
sleep 5 
#machines=$(sudo docker ps -a -q)
#if [ -n $machines ]
#	then
#		sudo docker stop $(sudo docker ps -a -q)
#fi
#sudo docker rm -f $(sudo docker ps -a -q)
#docker rmi $(sudo docker images -q)

sudo docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise $manager_ip:4000 consul://10.254.1.106:8500
sudo docker run -d swarm join --advertise=$manager:2375 consul://10.254.1.106:8500
}


docker_check
service_check
manager_setup
