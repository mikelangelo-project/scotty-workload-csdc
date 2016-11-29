# name: Cluster setup for manager node 
# auth: Mohammad Sahihi <msahihi at gwdg.de>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

#!/bin/bash


docker_check () {
	
if which docker >/dev/null;
	 then
		echo "\n+++++++++++++++++++++++++++++++"
		echo "+ Docker is already installed +"
		echo "+++++++++++++++++++++++++++++++\n"
	else
		echo "\n-------------------------------"
		echo "-   Docker is not installed   -"
		echo "-------------------------------\n"
		
		echo "\n+++++++++++++++++++++++++++++++"
		echo "+   Installing Docker .....   +"
		echo "++++++++++++++++++++++++++++++-\n"
		yum update
		curl -sSL https://get.docker.com/ | sh
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

echo "\n+++++++++++++++++++++++++++++++" 
echo "+  Setting up Swarm manager  +"
echo "+++++++++++++++++++++++++++++++\n" 
sudo docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://10.254.1.106:8500  --cluster-advertise=$manager_ip:2376 &
sleep 5 

ps=$(sudo docker ps --filter "name=swarm_manager" -a -q)
ru=$(sudo docker ps --filter "name=swarm_manager" -q)

if [ -n "$ps" ]
then
        echo "[I] Stopping Previous containers\n"
        sudo docker stop  $ru
        echo "\n"       
        echo "[I] Removing Previous containers\n"
        sudo docker rm -f $ps
        echo "\n"
fi

sudo docker run -d --name swarm_manager -p 4000:4000 swarm manage -H :4000 --replication --advertise $manager_ip:4000 consul://10.254.1.106:8500
echo "[+] Client Swarm manager is ready\n"

sudo docker run -d --name swarm_manager_node swarm join --advertise=$manager:2375 consul://10.254.1.106:8500
echo "[+] Swarm manager joined as node\n"
}

snap_check () {

if which snap >/dev/null;
         then
                echo "\n+++++++++++++++++++++++++++++++"
                echo "+ SNAP is already installed +"
                echo "+++++++++++++++++++++++++++++++\n"
        else
                echo "\n-------------------------------"
                echo "-   SNAP is not installed   -"
                echo "-------------------------------\n"

                yum update

                echo "\n+++++++++++++++++++++++++++++++"
                echo "+   Installing GO .....   +"
                echo "++++++++++++++++++++++++++++++-\n"

                chmod 700 asset/goinstall.sh
                bash asset/goinstall.sh --64

                echo "\n+++++++++++++++++++++++++++++++"
                echo "+   Installing SNAP .....   +"
                echo "++++++++++++++++++++++++++++++-\n"
                sudo curl -s https://packagecloud.io/install/repositories/intelsdi-x/snap/script.deb.sh | sudo bash
                sudo apt-get install -y snap-telemetry
                sudo systemctl start snap-telemetry
fi

}

load_snap_plugin () {

                echo "\n--------------------------------------"
                echo "-   Loading Collector Plugin .....   -"
                echo "--------------------------------------\n"

                snapctl plugin unload collector cloudsuite-dc 1
                snapctl plugin unload publisher mock-file 3
                snapctl plugin unload processor passthru 1
		
		snapctl plugin load asset/snap/snap-plugin-processor-passthru
		snapctl plugin load asset/snap/snap-plugin-publisher-mock-file
                snapctl plugin load asset/snap/snap-plugin-collector-cloudsuite-datacaching
                
		echo "\n--------------------------------------"
                echo "-      Creating SNAP Task .....      -"
                echo "--------------------------------------\n"
		
		snapctl task create -t asset/snap/datacahing-task.yaml

}

prepare_env () {


echo "\n+++++++++++++++++++++++++++++++"
echo "+    Preparing Environment    +"
echo "+++++++++++++++++++++++++++++++\n"

sudo bash /asset/setup_nfs.sh -r server -c clients.txt

sudo touch /var/log/benchmark/detail.csv
sudo chmod 777 /v/ar/log/benchmark/detail.csv


}

docker_check
service_check
manager_setup
prepare_env
load_snap_plugin
