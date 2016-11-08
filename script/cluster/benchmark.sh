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

	network_name="caching_network"
	ps=$(sudo docker -H :4000 ps --filter "name=dc-" -a -q)
	NOFS=4
network () {


	echo "\n++++++++++++++++++++++++++" 
	echo "+    Creating Network    +"
	echo "++++++++++++++++++++++++++\n" 
	
	echo "[+] Netowrk name : data_chaching"
	
	network=$(docker network ls -f NAME=$network_name -q)
	if [ -z "$network" ];
		then
			sudo docker network create --driver overlay $network_name
		else
			echo "[+] Network Exist"
	fi

}

stop_remove_all () {


	if [ -n "$ps" ]
	then
		echo "[I] Stopping Previous containers\n"
		sudo docker -H :4000 stop  $(docker -H :4000 ps --filter "name=dc-" -a -q)
		iecho "\n"	
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
		sudo docker -H :4000 run --name dc-server$NOFS --hostname dc-server$i --network $network_name -d cloudsuite/data-caching:server -t 4 -m 4096 -n 550
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

auto () {
network
stop_remove_all
create_server
create_client
run_benchmark
}
################################
# Check if parameters options  #
# are given on the commandline #
################################
while :
do
    case "$1" in
	
	-S | --SERVERS)
          if [ $# -nie 0 ]; then
            resolution="$2"   # You may want to check validity of $2
          fi
          shift 2
          ;;
	-h | --help)
          display_usage  # Call your function
          exit 0
          ;;
	-C | --CLIENT)
          display="$2"
           shift 2
           ;;
	-a | --automatic)
		auto	# Run all steps automatically
		# and write it in your help function display_help()
           shift 2
           ;;
	-SA | --stop-all)
		stop_remove_all
		shift
		;;
	--) # End of all options
          shift
          break
          ;;
	-*)
          echo "Error: Unknown option: $1" >&2
          ## or call function display_help
          exit 1 
          ;;
	*)  # No more options
          break
          ;;
    esac
done


