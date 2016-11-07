# name: Automated Creation of Docker Discovery
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash

display_usage() { 
	echo "This script must be run with super-user privileges." 
	echo -e "\nUsage:\n$0 [arguments] \n" 
	} 

# if less than two arguments supplied, display usage 
	if [  $# -le 1 ] 
	then 
		display_usage
		exit 1
	fi 
 
# check whether user had supplied -h or --help . If yes display usage 
	if [[$# == "--help"  || $# == "-h" ]]  
	then 
		display_usage
		exit 0
	fi 






echo "\n++++++++++++++++++++++++++" 
echo "+    Creating Network    +"
echo "++++++++++++++++++++++++++\n" 

network_name="caching_network"
echo "[+] Netowrk name : data_chaching"

network=$(docker network ls -f NAME=$network_name -q)
if [ -z "$network" ];
	then
		sudo docker network create --dirver overlay $network_name
	else
		echo "[+] Network Exist"
fi

echo "\n++++++++++++++++++++++++++" 
echo "+    Creating Servers    +"
echo "++++++++++++++++++++++++++\n" 

ps=$(sudo docker -H :4000 ps --filter "name=dc-" -a -q)
if [ -n "$ps" ]
then
	echo "[i] Stopping Previous containers\n"
	sudo docker -H :4000 stop  $(docker -H :4000 ps --filter "name=dc-" -a -q)
	echo "\n"	
	echo "[i] Removing Previous containers\n"
	sudo docker -H :4000 rm -f $(docker -H :4000 ps --filter "name=dc-" -a -q) 
	echo "\n"
fi

# Reading number of server from input 
for i in $(seq 1 1 $1)
do
	sudo docker -H :4000 run --name dc-server$i --network $network_name -d cloudsuite/data-caching:server -t 4 -m 4096 -n 550
	echo "[+] Server $i is ready\n"
done

echo "\n++++++++++++++++++++++++++" 
echo "+     Creating Client    +"
echo "++++++++++++++++++++++++++\n" 

sudo docker -H :4000 run -itd --name dc-client -v /home/ubuntu/client:/home/test --net caching_network cloudsuite/data-caching:client bash
	echo "[+] Client dc-client is ready\n"

echo "\n++++++++++++++++++++++++++" 
echo "+    Running Benchmark   +"
echo "++++++++++++++++++++++++++\n"

#Remove all logs
#sudo docker exec -d dc-client bash -c 'rm /home/test/*'

# Scaling the dataset and warming up the server
sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && for i in $(seq 1 1 '"$1"'); do echo "dc-server$i, 11211\n" ; done > docker_servers.txt'

sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '"$1"' -S 2 -D 4096 -j -T 1 >> /home/test/benchmark.log  && ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w'"$1"'  >> /home/test/benchmark.log'
echo "Benchamark is running in background"
