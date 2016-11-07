# name: Automated Creation of Docker Discovery 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


install_docker () {
	yum update
	curl -sSL https://get.docker.com/ | sh
}

if which docker >/dev/null; then
	echo "\n+++++++++++++++++++++++++++"
	echo "Docker is already installed"
	echo "+++++++++++++++++++++++++++\n"
else
	echo -e "Installing Docker\n ++++++++++++ "
	wait install_docker
fi
sudo docker stop $(docker ps -q)
sudo docker rm -f $(docker ps -a -q)
sudo service docker restart
