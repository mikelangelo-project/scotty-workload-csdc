# name: Automated Creation of Docker Discovery
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


display_usage() { 
cat <<EOF
Usage: $0 [options]

-h| --help           give this help list.

-S
--start-all
--stop-all

-TT|--first-option    this is my first option
-MM|--second-option   this is my second option
-NN

EOF
} 

# Initial primary variable
network_name="caching_network"
ps=$(sudo docker -H :4000 ps --filter "name=dc-" -a -q)


network () {


	echo "\n++++++++++++++++++++++++++" 
	echo "+    Creating Network    +"
	echo "++++++++++++++++++++++++++\n" 
	
	echo "[+] Netowrk name : data_chaching"
	
	network=$(docker network ls -f NAME=$network_name -q)
	if [ -z "$network" ];
		then
			sudo docker network create --driver overlay $network_name
			echo "[+] Network created"
		else
			echo "[+] Network Exist"
	fi

}

stop_remove_all () {


	if [ -n "$ps" ]
	then
		echo "[I] Stopping Previous containers\n"
		sudo docker -H :4000 stop  $(docker -H :4000 ps --filter "name=dc-" -a -q)
		echo "\n"	
		echo "[I] Removing Previous containers\n"
		sudo docker -H :4000 rm -f $(docker -H :4000 ps --filter "name=dc-" -a -q) 
		echo "\n"
	fi

}

create_server () {

	echo "\n++++++++++++++++++++++++++" 
	echo "+    Creating Servers    +"
	echo "++++++++++++++++++++++++++\n" 
	
	# Reading number of server from input 
	for i in $(seq 1 1 $NOFS)
	do
		sudo docker -H :4000 run --name dc-server$i --hostname dc-server$i --network $network_name -d cloudsuite/data-caching:server -t $NOFS -m $mm -n $nn
		echo "[+] Server $i is ready\n"
	done

}

create_client () {

	echo "\n++++++++++++++++++++++++++" 
	echo "+     Creating Client    +"
	echo "++++++++++++++++++++++++++\n" 
	
	sudo docker -H :4000 run -itd --name dc-client --hostname dc-client -v /home/ubuntu/client:/home/test --network $network_name cloudsuite/data-caching:client bash
		echo "[+] Client dc-client is ready\n"
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && for i in $(seq 1 1 '"$1"'); do echo "dc-server$i, 11211\n" ; done > docker_servers.txt'
}

run_benchmark () {

	echo "\n++++++++++++++++++++++++++" 
	echo "+    Running Benchmark   +"
	echo "++++++++++++++++++++++++++\n"
	
	
	# Scaling the dataset and warming up the server
	
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '"$NOFS"' -S 2 -D 4096 -j -T 1 >> /home/test/benchmark.log  && ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w'"$NOFS"'  >> /home/test/benchmark.log'
	echo "Benchamark is running in background"

}



#################################
# check command line parameters #
#################################
while :
do
	case "$1" in
		-h | --help)
		display_usage  # Call your function
		exit 0
		;;
		-n | --server-no)
		if [ $2 -ne 0 ]; then
		NOFS=$2 # Number of server to create
		fi
		shift
		;;
		-a | --auto)
		auto=1 # Number of server to create
		shift
		;;
		-sa | --stop-all)
		stop_remove_all
		shift
		;;
		-mm | --memory)
		mm=$2 # Number of server to create
		shift
		;;
		-nn | --bject-size)
		nn=$2 # Number of server to create
		shift
		;;
		-a | --auto)
		auto=1 # Number of server to create
		shift
		;;
		-a | --auto)
		auto=1 # Number of server to create
		shift
		;;
		--) # End of all options
		shift
		break
		;;
		-*)
		display_usage
		exit 1 
		;;
		\?)
		echo "Invalid option"
		;;
		*)  # No more options
		break
		;;
	esac
done




if [ "$NOFS" = "" ]
then
    NOFS=4
fi

if [ "$mm" = "" ]
then
    mm=4096
fi

if [ "$nn" = "" ]
then
    nn=550
fi

if [ "$auto" = 1 ]
then
network
stop_remove_all
create_server
create_client
run_benchmark

fi

