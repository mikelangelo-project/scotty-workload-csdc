# name: Cloudsuite benchmark in cluster
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash
#set -x

display_usage() { 
cat <<EOF
Usage: $0 [options]

-h  | --help             give this help list.

-a  | --auto             running whole benchmark and setup automatically
-sa | --stop-all         stop and remove all servers & client

-n  | --server-no        number of server (default: 4)
-tt | --server-threads   number of threads of server (default: 4)
-mm | --memory           dedicated memory (default: 4097)
-nn | --object-size      object size (default: 550)
-w  | --client-threats   number of client threads (default: 4)
-T  | --interval         interval between stats printing (default: 1)
-D  | --server-memory    size of main memory available to each memcached server in MB (default: 4096)
-S  | --scaling-factor   dataset scaling factor (default: 30)
-t  | --duration         runtime of loadtesting in seconds (default: run forever)
-g  | --fraction         fraction of requests that are gets (default: 0.8)
-c  | --connections      total TCP connections (default: 200)

EOF
} 

# Initial primary variable
network_name="caching_network"
ps=$(sudo docker -H :4000 ps --filter "name=dc-" -a -q)

network () {


	echo -e "\n++++++++++++++++++++++++++" 
	echo -e "+    Creating Network    +"
	echo -e "++++++++++++++++++++++++++\n" 
	
	echo -e "[+] Netowrk name : data_chaching"
	
	network=$(sudo docker network ls -f NAME=$network_name -q)
	if [ -z "$network" ];
		then
			sudo docker network create --driver overlay $network_name
			echo -e "[+] Network created"
		else
			echo -e "[+] Network Exist"
	fi

}

stop_remove_all () {


	if [ -n "$ps" ]
	then
		echo -e "[I] Stopping Previous containers\n"
		sudo docker -H :4000 stop  $(docker -H :4000 ps --filter "name=dc-" -a -q)
		echo -e "\n"	
		echo -e "[I] Removing Previous containers\n"
		sudo docker -H :4000 rm -f $(docker -H :4000 ps --filter "name=dc-" -a -q) 
		echo -e "\n"
	fi

}

create_server () {

	echo -e "\n++++++++++++++++++++++++++" 
	echo -e "+    Creating Servers    +"
	echo -e "++++++++++++++++++++++++++\n" 
	
	# Reading number of server from input 
	for i in $(seq 1 1 $n)
	do
		sudo docker -H :4000 run --name dc-server$i --hostname dc-server$i --network $network_name -d cloudsuite/data-caching:server -t $tt -m $mm -n $nn
		echo -e "[+] Server $i is ready\n"
	done

}

create_client () {

	echo -e "\n++++++++++++++++++++++++++" 
	echo -e "+     Creating Client    +"
	echo -e "++++++++++++++++++++++++++\n" 
	
	sudo docker -H :4000 run -itd --name dc-client --hostname dc-client -v /var/log/benchmark:/home/log --network $network_name cloudsuite/data-caching:client bash
		echo -e "[+] Client dc-client is ready\n"
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && for i in $(seq 1 1 '"$n"'); do echo -e "dc-server$i, 11211" ; done > docker_servers.txt'
}

run_benchmark () {

	echo -e "\n++++++++++++++++++++++++++" 
	echo -e "+    Running Benchmark   +"
	echo -e "++++++++++++++++++++++++++\n"

	# Scaling the dataset and warming up the server
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '"$w"' -S '"$S"' -D '"$D"' -j -T '"$T"' >> /home/log/warmup.log && stdbuf -o0 ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g '"$g"' -T '"$T"' -c '"$c"' -w'"$w"' -t '"$t"' >> /home/log/benchmark.log'

}




#################################
# check command line parameters #
#################################
while :
do
	case "$1" in
		-h | --help)
		display_usage
		exit 0
		;;
		-a | --auto)
		auto=1
		shift 
		;;
		-sa | --stop-all)
		stop_remove_all
		shift 
		;;
		-n | --server-no)
		n=$2
		shift 2 
		;;
		-tt | --server-threats)
		tt=$2
		shift 2
		;;
		-mm | --memory)
		mm=$2
		shift 2
		;;
		-nn | --object-size)
		nn=$2
		shift 2
		;;
		-w | --client-threads)
		w=$2
		shift 2
		;;
		-T | --interval)
		T=$2
		shift 2
		;;
		-D | --server-memory)
		D=$2
		shift 2
		;;
		-S | --scaling-factor)
		S=$2
		shift 2
		;;
		-t | --duration)
		t=$2
		shift 2
		;;
		-g | --fraction)
		=$2
		shift 2
		;;
		-c | --connections)
		c=$2
		shift 2
		;;
		--)
		shift 
		break
		;;
		-*)
		display_usage
		exit 1 
		;;
		\?)
		echo -e "Invalid option"
		;;
		*)
		display_usage
		break
		;;
	esac
done

if [ "$n" = "" ]
then
    n=2
fi

if [ "$tt" = "" ]
then
    tt=2
fi

if [ "$mm" = "" ]
then
    mm=4096
fi

if [ "$nn" = "" ]
then
    nn=550
fi

if [ "$w" = "" ]
then
    w=2
fi

if [ "$T" = "" ]
then
    T=1
fi

if [ "$D" = "" ]
then
    D=4096
fi

if [ "$S" = "" ]
then
    S=2
fi

if [ "$t" = "" ]
then
    t=0
fi

if [ "$g" = "" ]
then
    g=0.8
fi

if [ "$c" = "" ]
then
    c=200
fi

if [ "$auto" = 1 ]
then
	echo -e "#########################################" 
	echo -e "                                         "
	echo -e "         Benchmark Environment           "
	echo -e "                                         "
	echo -e "       -------- Server -------           "
	echo -e "                                         "
	echo -e "     Number of Server: $n                "
	echo -e "     Server Threads:   $tt               "
	echo -e "     Dedicated memory: $mm               "
	echo -e "     Object Size:      $nn               "
	echo -e "                                         "
	echo -e "       --------- Client ------           "
	echo -e "                                         "
	echo -e "     Client threats:   $w                "
	echo -e "     Interval:         $T                "
	echo -e "     Server memory:    $D                "
	echo -e "     Scaling factor:   $S                "
	echo -e "     Fraction:         $g                "
	echo -e "     Connections:      $c                "
	echo -e "     Duration:         $t                "
	echo -e "                                         "
	echo -e "#########################################"
	
	network
	stop_remove_all
	create_server
	create_client
	run_benchmark
	
	sudo pkill tail
	tail -f /var/log/benchmark/benchmark.log | stdbuf -o0 awk -f asset/output.awk >> /var/log/benchmark/detail.csv&
	echo -e "\n[+] The Benchmark is running in the background\n"

fi

