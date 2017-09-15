# name: Cloudsuite benchmark in cluster
# auth: Mohammad Sahihi <msahihi1 at gwdg.de>
# vim: ts=4 syntax= bash sw=4 sts=4 sr noet

#!/bin/bash
#set -x
#set -e



#                                                                       #
#               D I S P L A Y   U S A G E   F U C N T I O N             #
#                                                                       #

display_usage() {
cat <<EOF
Usage: $0 [options]

	-h  | --help             Give this help list.

	-a  | --auto             Running whole benchmark and setup automatically
	-R  | --remove-all         Stop and remove all servers & client

	-n  | --server-no        Number of server (default: 4)
	-tt | --server-threads   Number of threads of server (default: 4)
	-mm | --memory           Dedicated memory (default: 4096)
	-nn | --object-size      Object size (default: 550)
	-w  | --client-threats   Number of client threads (default: 4)
	-T  | --interval         Interval between stats printing (default: 1)
	-D  | --server-memory    Size of main memory available to each memcached server in MB (default: 4096)
	-S  | --scaling-factor   Dataset scaling factor (default: 2)
	-t  | --duration         Runtime of loadtesting in seconds (default: run forever)
	-g  | --fraction         Fraction of requests that are gets (default: 0.8)
	-c  | --connections      Total TCP connections (default: 200)

EOF
}

#                                                                       #
#          C R E A T E   O V E R L A Y   N E T W O R K                  #
#                                                                       #
ps=$(sudo docker -H :4000 ps --filter "name=dc-" -a -q)
network() {
sudo docker -H:4000 network rm caching_network

network_name="caching_network"

	echo -e "---> Netowrk name : $network_name"
	network=$(sudo docker network ls -f NAME=$network_name -q)
	if [ -z "$network" ];
		then
			sudo docker -H:4000 network create --opt com.docker.network.driver.mtu=1450 --driver overlay $network_name
			echo -e "[+] Network created"
		else
			echo -e "---> Network Exist"
	fi

}

#                                                                       #
#          R E M O V I N G   A L L   C O N T A I N E R S                #
#                                                                       #

remove_all () {

	if [ -n "$ps" ]
	then
		echo -e "\n[+] Stopping Previous containers"
		sudo docker -H :4000 stop  $(sudo docker -H :4000 ps --filter "name=dc-" -a -q)
		echo -e "\n[+] Removing Previous containers"
		sudo docker -H :4000 rm -f $(sudo docker -H :4000 ps --filter "name=dc-" -a -q)
	fi
	unload_snap_plugin

}

#                                                                       #
#           B E N C H M A R K   S E R V E R S   N O D E S               #
#                                                                       #

create_server () {


	echo -e "\n[+] Creating Servers\n"
	for i in $(seq 1 1 $n)
	do
		sudo docker -H :4000 run --name dc-server$i --hostname dc-server$i -e constraint:node!=$(hostname) --network $network_name -d cloudsuite/data-caching:server -t $tt -m $mm -n $nn
		echo -e "[+] Server $i is ready"
	done

}


#                                                                       #
#               B E N C H M A R K  C L I E N T  N O D E                 #
#                                                                       #

create_client () {

      # By default docker swarm manager join as docker swarm node \
			# to host cloudsuite datacaching client container.

	echo -e "\n[+]  Creating Client\n"

	sudo docker -H :4000 run -itd --name dc-client --hostname dc-client -e constraint:node==$(hostname) -v /var/log/benchmark:/home/log --network $network_name cloudsuite/data-caching:client bash
	echo -e "[+] Client dc-client is ready\n"
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && for i in $(seq 1 1 '"$n"'); do echo -e "dc-server$i, 11211" ; done > docker_servers.txt'


}


#                                                                       #
#                  R U N N I N G   B E N C H M A R K                    #
#                                                                       #


run_benchmark () {


	echo -e "[+] Warming up the servers. "
	sleep 2
	echo -e "[!] It may takes few minutes."
	# Scaling the dataset and warming up the server
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ &&  stdbuf -o0 ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '"$w"' -S '"$S"' -D '"$D"' -j -T '"$T"' >> /home/log/warmup.log && stdbuf -o0 ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g '"$g"' -T '"$T"' -c '"$c"' -w '"$w"' -t '"$t"' >> /home/log/benchmark.log'

}

#                                                                       #
#               U N L O A D   S N A P   P L U G I N                     #
#                                                                       #

unload_snap_plugin () {

echo -e "[+] Unloading Previous Collector Plugin ....."
snaptel plugin unload processor tag 3 > /dev/null
echo -e "[X] Tag Processor Plugin unloaded"
snaptel plugin unload publisher influxdb 17 > /dev/null
echo -e "[X] Influxdb Publisher Plugin unloaded"
snaptel plugin unload collector cloudsuite-dc 1 > /dev/null
echo -e "[X] Cloudsuite-datacaching Collector Plugin unloaded\n"

echo -e "[+] Removing Previous SNAP Task ....."
snaptel task list | cut -f 1 | tail -n +2 | while read LINE
do
	snaptel task stop ${LINE} > /dev/null
	snaptel task remove ${LINE} > /dev/null
	echo -e "---> Task ${LINE} removed"
done
}

#                                                                       #
#   C A P T U R E   M E T R I C S   V I A   S N A P   P L U G I N S     #
#                                                                       #

load_snap_plugin(){

echo -e "[+] Loading Collector Plugin ....."
snaptel plugin load $PWD/asset/snap/snap-plugin-processor-tag > /dev/null
echo -e "[*] Tag Processor Plugin Loaded"
snaptel plugin load $PWD/asset/snap/snap-plugin-publisher-influxdb > /dev/null
echo -e "[*] Influxdb Publisher Plugin Loaded"
snaptel plugin load $PWD/asset/snap/snap-plugin-collector-cloudsuite-datacaching > /dev/null
echo -e "[*] Cloudsuite-datacaching Collector Plugin Loaded\n"

}

#                                                                       #
#                C R E A T E   S N A P   T A S K                        #
#                                                                       #

create_snap_task() {

echo -e "[+] Creating SNAP Task ....."
snaptel task create -t asset/snap/datacaching-task.yaml && echo -e "[+] Cloudsuite-datacaching SNAP Task created and is running"

}

wait_time() {
if [ "$t" -eq "0" ]; then

    echo -e "[!] The benchmark runs forever "
    echo -e "Pres CTRL+C to stop..."
    while :
    do
    sleep 1
	done
else
	echo -e "[!] The benchmark takes $t seconds to be completed"
	sleep $t;
fi

}

########################################################################
#                                                                      #
#                                 M A I N                              #
#                                                                      #
########################################################################I

while [[ $# -gt 0 ]]
do
key="$1"
	case $key in
		-h|--help)
		display_usage
		exit 0
		;;
		-a|--auto)
		auto=1
		shift
		;;
		-R|--remove-all)
		remove_all
		shift
		;;
		-n|--server-no)
		n=$2
		shift 2
		;;
		-tt|--server-threats)
		tt=$2
		shift 2
		;;
		-mm|--memory)
		mm=$2
		shift 2
		;;
		-nn|--object-size)
		nn=$2
		shift 2
		;;
		-w|--client-threads)
		w=$2
		shift 2
		;;
		-T|--interval)
		T=$2
		shift 2
		;;
		-D|--server-memory)
		D=$2
		shift 2
		;;
		-S|--scaling-factor)
		S=$2
		shift 2
		;;
		-t|--duration)
		t=$2
		shift 2
		;;
		-g|--fraction)
		g=$2
		shift 2
		;;
		-c|--connections)
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
    n=4
fi

if [ "$tt" = "" ]
then
    tt=4
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
    w=4
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
	echo -e "+---------------------------------------+"
	echo -e "                                         "
	echo -e "           Benchmark Environment         "
	echo -e "                                         "
	echo -e "      ---------- Server ---------        "
	echo -e "                                         "
	echo -e "        Number of Server: $n             "
	echo -e "        Server Threads:   $tt            "
	echo -e "        Dedicated memory: $mm            "
	echo -e "        Object Size:      $nn            "
	echo -e "                                         "
	echo -e "       --------- Client ---------        "
	echo -e "                                         "
	echo -e "        Client threats:   $w             "
	echo -e "        Interval:         $T             "
	echo -e "        Server memory:    $D             "
	echo -e "        Scaling factor:   $S             "
	echo -e "        Fraction:         $g             "
	echo -e "        Connections:      $c             "
	echo -e "        Duration:         $t             "
	echo -e "                                         "
	echo -e "+---------------------------------------+"

	sudo rm -rf /var/log/benchmark/*
	remove_all
	network
	create_server
	create_client
	load_snap_plugin
	run_benchmark
	while [ ! -f /var/log/benchmark/benchmark.log ];
	do
	    sleep 1;
	done;
	echo -e "[+] Servers are wamred up"
  	echo -e "[+] Running Benchmark ...\n"
	echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0" >> /var/log/benchmark/detail.csv
	nohup stdbuf -o0 tail -f /var/log/benchmark/benchmark.log | nohup stdbuf -o0 awk -f asset/output.awk >> /var/log/benchmark/detail.csv&
	sleep 10; # to be sure that we get the output in detail.csv
	create_snap_task
	# stdbuf -o0 snaptel task watch $(snaptel task list | cut -f 1 | tail -n +2 | tail)
	echo -e "[+] The Benchmark is running in the background"
	wait_time
fi
