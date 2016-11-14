# name: Cloudsuite benchmark in cluster
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


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
	for i in $(seq 1 1 $n)
	do
		sudo docker -H :4000 run --name dc-server$i --hostname dc-server$i --network $network_name -d cloudsuite/data-caching:server -t $tt -m $mm -n $nn
		echo "[+] Server $i is ready\n"
	done

}

create_client () {

	echo "\n++++++++++++++++++++++++++" 
	echo "+     Creating Client    +"
	echo "++++++++++++++++++++++++++\n" 
	
	sudo docker -H :4000 run -itd --name dc-client --hostname dc-client -v /home/ubuntu/client:/home/log --network $network_name cloudsuite/data-caching:client bash
		echo "[+] Client dc-client is ready\n"
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && for i in $(seq 1 1 '"$1"'); do echo "dc-server$i, 11211\n" ; done > docker_servers.txt'
}

run_benchmark () {

	echo "\n++++++++++++++++++++++++++" 
	echo "+    Running Benchmark   +"
	echo "++++++++++++++++++++++++++\n"
	
	
	# Scaling the dataset and warming up the server
	sudo docker -H :4000 exec -d dc-client bash -c 'if [ -f /home/log/benchmark.log ]; then rm /home/log/benchmark.log; fi && if [ -f /home/log/warmup.log ]; then rm /home/log/warmup.log; fi && cd /usr/src/memcached/memcached_client/ && ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '"$w"' -S '"$S"' -D '"$D"' -j -T '"$T"' >> /home/log/warmup.log  && ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g '"$g"' -T '"$T"' -c '"$c"' -w'"$w"' -t '"$t"' >> /home/log/benchmark.log  '
	echo "Benchamark is running in background"

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
		shift
		;;
		-tt | --server-threats)
		tt=$2
		shift
		;;
		-mm | --memory)
		mm=$2
		shift
		;;
		-nn | --object-size)
		nn=$2
		shift
		;;
		-w | --client-threads)
		w=$2
		shift
		;;
		-T | --interval)
		T=$2
		shift
		;;
		-D | --server-memory)
		D=$2
		shift
		;;
		-S | --scaling-factor)
		S=$2
		shift
		;;
		-t | --duration)
		t=$2
		shift
		;;
		-g | --fraction)
		=$2
		shift
		;;
		-c | --connections)
		c=$2
		shift
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
		echo "Invalid option"
		;;
		*)
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
	echo "#########################################" 
	echo "                                         "
	echo "         Benchmark Environment           "
	echo "                                         "
	echo "       -------- Server -------           "
	echo "                                         "
	echo "     Number of Server: $n                "
	echo "     Server Threads:   $tt               "
	echo "     Dedicated memory: $mm               "
	echo "     Object Size:      $nn               "
	echo "                                         "
	echo "       --------- Client ------           "
	echo "                                         "
	echo "     Client threats:   $w                "
	echo "     Interval:         $T                "
	echo "     Server memory:    $D                "
	echo "     Scaling factor:   $S                "
	echo "     Fraction:         $g                "
	echo "     Connections:      $c                "
	echo "     Duration:         $t                "
	echo "                                         "
	echo "#########################################"
	
	network
	stop_remove_all
	create_server
	create_client
	run_benchmark

fi

