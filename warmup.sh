# name: Cloudsuite benchmark in cluster
# auth: Mohammad Sahihi <msahihi1 at gwdg.de>
# vim: ts=4 syntax= bash sw=4 sts=4 sr noet

#!/bin/bash
# set -x
# set -e



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
#                  R U N N I N G   B E N C H M A R K                    #
#                                                                       #


run_benchmark () {


	echo -e "[+] Warming up the servers. "
	sleep 2
	echo -e "[!] It may takes few minutes."
	# Scaling the dataset and warming up the server
	sudo docker -H :4000 exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ &&  stdbuf -o0 ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '"$w"' -S '"$S"' -D '"$D"' -j -T '"$T"' >> /home/log/warmup.log && stdbuf -o0 ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g '"$g"' -T '"$T"' -c '"$c"' -w '"$w"' -t '"$t"' >> /home/log/benchmark.log'

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
	echo -e "+--------------------------+"
	echo -e "                            "
	echo -e "  Benchmark configuration   "
	echo -e "                            "
	echo -e " --------- Server --------- "
	echo -e "                            "
	echo -e " Number of Server: $n       "
	echo -e " Server Threads:   $tt      "
	echo -e " Dedicated memory: $mm      "
	echo -e " Object Size:      $nn      "
	echo -e " --------- Client --------- "
	echo -e "                            "
	echo -e " Client threats:   $w       "
	echo -e " Interval:         $T       "
	echo -e " Server memory:    $D       "
	echo -e " Scaling factor:   $S       "
	echo -e " Fraction:         $g       "
	echo -e " Connections:      $c       "
	echo -e " Duration:         $t       "
	echo -e "                            "
	echo -e "+--------------------------+"

	run_benchmark
	while [ ! -f /var/log/benchmark/benchmark.log ];
	do
	    sleep 1;
	done;
	echo -e "[+] Servers are wamred up"
fi
