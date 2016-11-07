#sudo docker -H :4000 start dc-client

echo "\n++++++++++++++++++++++++++" 
echo "+    Creating Network    +"
echo "++++++++++++++++++++++++++\n" 

network=$(docker network ls -f NAME=caching_network -q)
if [ -z "$network" ];
	then
		docker network create caching_network
	else
		echo "+ Network Exist"
fi

echo "\n++++++++++++++++++++++++++" 
echo "+    Creating Servers      +"
echo "++++++++++++++++++++++++++\n" 

docker stop  dc-server1 dc-server2 dc-server3 dc-server4 dc-client
docker rm -f dc-server1 dc-server2 dc-server3 dc-server4 dc-client

docker run --name dc-server1 --net caching_network -d cloudsuite/data-caching:server -t 4 -m 4096 -n 550
docker run --name dc-server2 --net caching_network -d cloudsuite/data-caching:server -t 4 -m 4096 -n 550
docker run --name dc-server3 --net caching_network -d cloudsuite/data-caching:server -t 4 -m 4096 -n 550
docker run --name dc-server4 --net caching_network -d cloudsuite/data-caching:server -t 4 -m 4096 -n 550

echo "\n++++++++++++++++++++++++++" 
echo "+     Creating Client    +"
echo "++++++++++++++++++++++++++\n" 

docker run -itd --name dc-client -v /home/ubuntu/client:/home/test --net caching_network cloudsuite/data-caching:client bash

echo "\n++++++++++++++++++++++++++" 
echo "+    Running Benchmark   +"
echo "++++++++++++++++++++++++++\n"

#Remove all logs
#sudo docker exec -d dc-client bash -c 'rm /home/test/*'

# Scaling the dataset and warming up the server
sudo docker exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client/ && ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w 4 -S 2 -D 4096 -j -T 1 > /home/test/scale-warmup.log && ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w 8 >> /home/test/benchmark.log'

#Warming Up the servers
#sudo docker exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client && nohup ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w 4 -S 1 -D 4096 -j -T 1 >> /home/test/warmup.log 2>&1& '

#Running the benchmark
#sudo docker exec -d dc-client  bash -c 'cd /usr/src/memcached/memcached_client/ && nohup ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w 8 >> /home/test/benchmark.log 2>&1&'

#Running the benchmark RPS where rps is 90% of the maximum number of requests per second achieved using the previous command.
#sudo docker exec -d dc-client bash -c 'cd /usr/src/memcached/memcached_client && ./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w 8 -e -r rps >> /home/test/rps.log >2&1&'
