# CloudSuite Data Caching Benchmark Using Docker Swarm 

[![N|Solid](https://www.gwdg.de/GWDG-Theme-1.0-SNAPSHOT/images/gwdg_logo.svg)](https://nodesource.com/products/nsolid)

## Overview
[Cloudsuite] is a benchmark suite for cloud service and this implementation let you run a [Data Caching] benchmar kon multiple server using overlay network on docker swarm.

## Requirements
  - At least 3 Worker/Host (One Key Value Store Host, One Swarm Manager Host, One Swarm Client Host)
  - All hosts must be access to the internet

This text you see here is *actually* written in Markdown! To get a feel for Markdown's syntax, type some text into the left window and watch the results in the right.

# Benchmark
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
To run benchmark enterb below command
```sh
$ ./benchmark -a
```
This command by defaul creates 2 CloudSuite Servers and 1 Cloudsuite Client. The container for CloudSuite Client would be created on client host. The CloudSuite Client generates request for the CloudSuite Servers and store the output to client host every second. Then SNAP collectore reads this output each second and get metrics from that.

### SNAP Plugins

Currentlt SNAP using following plugin to read metrics

* [asset/snap/snap-plugin-collector-cloudsuite-datacaching] [SPcollector]
* [asset/snap/snap-plugin-processor-passthru] [SPprocessor]
* [asset/snap/snap-plugin-publisher-mock-file] [SPpublisher]

### SNAP Task
You can find SNAP task here : [asset/snap/datacahing-task.yaml] [STask]

*Please do not change anything value in task file otherwise the task would be beroken.*


### Development


   [Cloudsuite]: <http://cloudsuite.ch>
   [Data Caching]: <https://github.com/ParsaLab/cloudsuite/tree/master/benchmarks/data-caching>
   [SPcollector]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/snap-plugin-collector-cloudsuite-datacaching>
   [SPprocessor]:  <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/snap-plugin-processor-passthru>
   [SPpublisher]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/snap-plugin-publisher-mock-file>
   [STask]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/master/asset/snap/datacahing-task.yaml>
   
