
t=$1
#                                                                       #
#                C R E A T E   S N A P   T A S K                        #
#                                                                       #

create_snap_task() {

echo -e "[+] Creating SNAP Task ....."
snaptel task create -t asset/snap/datacaching-task.json && echo -e "[+] Cloudsuite-datacaching SNAP Task created and is running"
}

#                                                                       #
#                     W A I T   F U N C T I O N                         #
#                                                                       #

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

#                                                                       #
#                        M A I N   F U N C T I O N                      #
#                                                                       #
echo -e "[+] Running Benchmark ...\n"
echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0" >> /var/log/benchmark/detail.csv
nohup stdbuf -o0 tail -f /var/log/benchmark/benchmark.log | nohup stdbuf -o0 awk -f asset/output.awk >> /var/log/benchmark/detail.csv&
sleep 10; # to be sure that we get the output in detail.csv
create_snap_task
# stdbuf -o0 snaptel task watch $(snaptel task list | cut -f 1 | tail -n +2 | tail)
echo -e "[+] The Benchmark is running in the background"
wait_time