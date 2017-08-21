CloudSuite Data Caching
===================

[![N|Solid](https://www.gwdg.de/GWDG-Theme-1.0-SNAPSHOT/images/gwdg_logo.svg)](https://nodesource.com/products/nsolid)

## Overview

CloudSuite Data Caching workload is desigend to work with Scotty CI framework. Thiw workload runs a [Data Caching] benchmark on multiple server using overlay network on docker swarm over Openstack Cloud. <br/>
CloudSuite Data caching workload uses Memcached data caching server and twitter dataset to simulate twitter data caching server.

### Parameteres
Parameteres used in this benchamrk are defined in workload.yaml file in "params" sections.
```yaml
params:
  server_no: 4
  server_threads: 4
  memory: 4096
  object_size: 550
  client_threats: 4
  interval: 1
  server_memory: 4096
  scaling_factor: 2
  duration: 120
  fraction: 0.8
  connection: 200
  ```
  by default workload runs only for 120 seconds but if you want to run forever you need to change **duration** to **0**

### Prerequisite
 This workload uses resource deployment resource to run on. <br/>
 please used **csdc_res** as key when you define your workload in experiment.yaml .
 In below a sample of defining this workload has been given.

 ```yaml
 - name: csdc
   generator: file:workload/csdc
   resources:
     csdc_res: OpenStack_Swarm
   params:
     server_no: 4
     server_threads: 4
     memory: 4096
     object_size: 550
     client_threats: 4
     interval: 1
     server_memory: 4096
     scaling_factor: 2
     duration: 120
     fraction: 0.8
     connection: 200
     greeting: '------> CloudSuite Data Caching Workload <------'
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
