# name: Cluster setup for manager node 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


docker_check () {
	
if which docker >/dev/null;
	 then
		echo -e "\n+++++++++++++++++++++++++++++++"
		echo -e "+ Docker is already installed +"
		echo -e "+++++++++++++++++++++++++++++++\n"
	else
		echo -e "\n-------------------------------"
		echo -e "-   Docker is not installed   -"
		echo -e "-------------------------------\n"
		
		echo -e "\n+++++++++++++++++++++++++++++++"
		echo -e "+   Installing Docker .....   +"
		echo -e "++++++++++++++++++++++++++++++-\n"
		curl -sSL https://get.docker.com/ | sh
		sudo service docker stop

fi

}

docker_daemon=$(sudo netstat -tulpn | grep dockerd | wc -l)
docker_service=$(sudo service docker status | cut -d' ' -f2)
manager_ip=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

service_check (){
if  test "${docker_service#*"running"}" != $docker_service
	then
		sudo service docker stop
		sleep 2
		if [ -f /var/lock/docker.pid ]; then
			sudo rm /var/lock/docker.pid
		fi
fi

if [ -n $docker_daemon ];
	then
		sudo pkill dockerd
		sleep 2
		if [ -f /var/lock/docker.pid ]; then
		
		sudo rm /var/lock/docker.pid
		fi
fi
}

manager_setup () {

echo -e "\n+++++++++++++++++++++++++++++++" 
echo -e "+  Setting up Swarm manager  +"
echo -e "+++++++++++++++++++++++++++++++\n" 
sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=$manager_ip:2376 &
sleep 5 

ps=$(sudo docker ps --filter "name=swarm_manager" -a -q)
ru=$(sudo docker ps --filter "name=swarm_manager" -q)

if [ -n "$ps" ]
then
        echo -e "[I] Stopping Previous containers\n"
        sudo docker stop  $ru
        echo -e "\n[I] Removing Previous containers\n"
        sudo docker rm -f $ps
        echo -e "\n"
fi

sudo docker run -d --name swarm_manager -p 4000:4000 swarm manage -H :4000 --replication --advertise $manager_ip:4000 consul://10.254.1.106:8500
echo -e "[+] Client Swarm manager is ready\n"

sudo docker run -d --name swarm_manager_node swarm join --advertise=$manager:2375 consul://10.254.1.106:8500
echo -e "[+] Swarm manager joined as node\n"
}

snap_check () {

if which snap >/dev/null;
         then
                echo -e "\n+++++++++++++++++++++++++++++++"
                echo -e "+ SNAP is already installed +"
                echo -e "+++++++++++++++++++++++++++++++\n"
        else
                echo -e "\n-------------------------------"
                echo -e "-   SNAP is not installed   -"
                echo -e "-------------------------------\n"


                echo -e "\n+++++++++++++++++++++++++++++++"
                echo -e "+   Installing GO .....   +"
                echo -e "++++++++++++++++++++++++++++++-\n"

                chmod 700 asset/goinstall.sh
                bash asset/goinstall.sh --64

                echo -e "\n+++++++++++++++++++++++++++++++"
                echo -e "+   Installing SNAP .....   +"
                echo -e "++++++++++++++++++++++++++++++-\n"
                sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash
                sudo apt-get install -y snap-telemetry
                sudo service snap-telemetry start
fi

}

prepare_env () {


echo -e "\n+++++++++++++++++++++++++++++++"
echo -e "+    Preparing Environment    +"
echo -e "+++++++++++++++++++++++++++++++\n"

sudo bash asset/setup_nfs.sh -r server -c asset/clients.txt

sudo touch /var/log/benchmark/detail.csv
sudo chmod 777 /var/log/benchmark/detail.csv
echo -e "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\n" >> /var/log/benchmark/detail.csv


sudo touch /var/log/benchmark/benchmark.log
sudo chmod 777 /var/log/benchmark/benchmark.log


}

load_snap_plugin () {

                echo -e "\n--------------------------------------"
                echo -e "-   Loading Collector Plugin .....   -"
                echo -e "--------------------------------------\n"

                snaptel plugin unload collector cloudsuite-dc 1
                snaptel plugin unload publisher mock-file 3
                snaptel plugin unload processor passthru 1
		
		snaptel plugin load asset/snap/snap-plugin-processor-passthru
		snaptel plugin load asset/snap/snap-plugin-publisher-mock-file
                snaptel plugin load asset/snap/snap-plugin-collector-cloudsuite-datacaching
                
		echo -e "\n--------------------------------------"
                echo -e "-      Creating SNAP Task .....      -"
                echo -e "--------------------------------------\n"
		
		snaptel task list | cut -f 1 | tail -n +2 | while read LINE
		do
		snaptel task stop $LINE
		snaptel task remove $LINE
		done
	
		snaptel task create -t asset/snap/datacahing-task.yaml

}


docker_check
service_check
manager_setup
snap_check
prepare_env
load_snap_plugin
