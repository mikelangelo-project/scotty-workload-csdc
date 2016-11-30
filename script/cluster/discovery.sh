# name: Cluster setup for discovery node
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


install_docker () {
	yum update
	curl -sSL https://get.docker.com/ | sh
}

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

docker_daemon=$(sudo netstat -tulpn | grep dockerd | wc -l)
docker_service=$(sudo service docker status | cut -d' ' -f2)

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

sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock &
sleep 2 
sudo docker stop consul
sudo docker rm -f consul
sudo docker rmi $(sudo docker images -q)
sudo docker run -d -p 8500:8500 --name=consul progrium/consul -server -bootstrap
