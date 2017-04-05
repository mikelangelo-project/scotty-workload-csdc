Automation and Integration of a CloudSute Datacahing Benchmark into Openstack Cloud
===================

[![N|Solid](https://www.gwdg.de/GWDG-Theme-1.0-SNAPSHOT/images/gwdg_logo.svg)](https://nodesource.com/products/nsolid)

## Overview
[Cloudsuite] is a benchmark suite for cloud service. This implementation aims to run a [Data Caching] benchmark on multiple server using overlay network on docker swarm over Openstack Cloud. It is possible to run the benchmark either On Opnestack cloud or Virtual machine. The difference between these two is that, in Openstack everything would be run automatically, from creating virtual machines to running the benchmark, however in virtual machine mode, you need to create machines by your self and then run scripts manually on each of virtual machines.

# 1) Running On Openstack using heat template
### Prerequisites
  - Openstack cloud with access to create 3 virtual machines, create network, 1 floating ip
  - Minimum of 14 GB  memory
  - Minimum of 3 VCPU
  - access to Openstack heat API
  - python Fabric library
  - source openrc file from openstack

### Configuration
Script will creates virtual machines using OpenStack Heat API from [heat_template/docker-swarm.yaml][Heat Config].
You need to just change default values of  "keyvalue_flavor", "manager_flavor","client_flavor","image_id" .

### Running The Test
Inorder tor run bencharmk on openstack you just need to run
```sh
python run.py -a
```
more option on
```sh
python run.py -h
```

# 2) Running The Virtual machine

### Prerequisites
  - At least 3 Worker/Host (One Key Value Store Host, One Swarm Manager Host, One Swarm Client Host)
    - Keyvalue store (A node running Ubuntu 16.04 with 2GB memory)
    - Manager Host (A node running Ubuntu 16.04 with 4GB memory)
    - Client Host (A node running Ubuntu 16.04 with 8GB memory)
  - All hosts must be access to the internet

_**it is possbile to run clinet with lower memory but you have to configure your test propery to avoid craching during the test.**_
### Running The Test
In order to conduct a benchmark first you need to setup docker and primary setup.

### Setup Docker Hosts
Enter below command on Key Value store host.
```sh
$ ./docker_setup.sh -r keystore
```
Enter below command on manager host.
```sh
$ ./docker_setup.sh -r manager -k <IP ADDRESS OF KEY VALUE STORE>
```
Enter below command on client host.
```sh
$ ./docker_setup.sh -r client -k <IP ADDRESS OF KEY VALUE STORE>
```
Now every host is running docker and all of them connected to eachother using docker swarm

### Running Benchmark
To run benchmark enter below command
```sh
$ ./benchmark -a
```
This command by defaul creates 2 CloudSuite Servers and 1 Cloudsuite Client. The container for CloudSuite Client would be created on client host. The CloudSuite Client generates request for the CloudSuite Servers and store the output to client host every second. Then SNAP collector reads the output each second and get metrics from that.
#### Aditional Options
If you want to custoimze your benchmark you can use following options.
```sh
Usage: ./benchmark.sh [options]

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
```
## OUTPUT
You can find the output file in manager host in '/var/log/benchmark/detail.csv' directory

### SNAP Plugins

Currently, SNAP using following plugin to read metrics

* [asset/snap/snap-plugin-collector-cloudsuite-datacaching] [SPcollector]
* [asset/snap/snap-plugin-processor-tag] [SPprocessor]
* [asset/snap/snap-plugin-publisher-influxdb] [SPpublisher]

### SNAP Task
You can find SNAP task here : [asset/snap/datacahing-task.yaml] [STask]
*Please do not change anything value in task file otherwise the task would be beroken.*

## Troubleshoot
If your network interface is anything rather than `eth0` please change it in [docker_setup.sh](docker_setup.sh) line 28
```sh
...
host_ip=$(sudo /sbin/ifconfi eth0| grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
...
```
# Built With

* [Openstack](https://www.openstack.org/) - Used for Heat template
* [Cloudsuite - Data Caching](http://cloudsuite.ch/datacaching/) - Benchmark suite
* [Docker](https://www.docker.com/) - Used to run Cloudsuite Containers
* [SNAP](https://github.com/intelsdi-x/snap) - Used to collect data
* [GO Language](https://golang.org/) - Used to compile  & run SNAP

## Author
Name: Mohammad Sahihi Benis
Email: mohammad.sahihi-benis@gwdg.de

License
-------
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


   [Cloudsuite]: <http://cloudsuite.ch>
   [Data Caching]: <https://github.com/ParsaLab/cloudsuite/tree/master/benchmarks/data-caching>
   [SPcollector]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/snap-plugin-collector-cloudsuite-datacaching>
   [SPprocessor]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/snap-plugin-processor-tag>
   [SPpublisher]:<https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/snap-plugin-publisher-influxdb>
   [STask]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/datacaching-task.yaml>
   [run]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/heat_template/run.py>
   [Heat Config]: https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/raw/master/heat_template/docker-swarm.yaml
