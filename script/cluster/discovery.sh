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
sleep 5 
sudo docker stop consul
#machines=$(sudo docker ps -a -q)
#if [ -n $machines ]
#	then
#		sudo docker stop $(sudo docker ps -a -q)
#fi
#sudo docker rm -f $(sudo docker ps -a -q)
sudo docker rm -f consul
#docker rmi $(sudo docker images -q)
sudo docker run -d -p 8500:8500 --name=consul progrium/consul -server -bootstrap
