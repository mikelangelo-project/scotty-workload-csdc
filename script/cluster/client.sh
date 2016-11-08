# name: Automated Creation of Docker Discovery 
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
		echo -e "Installing Docker\n ++++++++++++ "
		install_docker
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
	sleep 2
	if [ -f /var/lock/docker.pid ]; then
		sudo rm /var/lock/docker.pid
	fi
fi
sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=10.254.1.95:2376 &
sleep 5 
#machines=$(sudo docker ps -a -q)
#if [ -n $machines ]
#	then
#		sudo docker stop $(sudo docker ps -a -q)
#fi
#sudo docker rm -f $(sudo docker ps -a -q)
#docker rmi $(sudo docker images -q)
sudo docker run -d swarm join --name swarm_client --advertise=10.254.1.95:2375 consul://10.254.1.106:8500
