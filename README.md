CloudSuite Data Caching benchmark workload
------------------------------------------


[![N|Solid](https://www.gwdg.de/GWDG-Theme-1.0-SNAPSHOT/images/gwdg_logo.svg)](https://nodesource.com/products/nsolid)


## Overview

Cloudsuite is a benchmark suite for cloud service. This implementation aims to run a Data Caching benchmark on multiple server using overlay network on docker swarm over Openstack Cloud. for more info look on [Cloudsuite].<br>
This benchmark collect all the data using [data caching][Data Caching] collector, tag using [tag-processor] and push them to influxdb using [influxdb publisher][influxdb-publisher].

## Requirements

This workload only works with OpenStack Swarm resource.
use [asset/stack.yaml][Stack Config] as stack configuration file.

## Parameters

list of all parameters available on [workload.yaml][workload]


## Built With

* [Cloudsuite - Data Caching](http://cloudsuite.ch/datacaching/) - Benchmark suite
* [SNAP](https://github.com/intelsdi-x/snap) - Used to collect data
* [GO Language](https://golang.org/) - Used to compile  & run SNAP


   [Cloudsuite]: <http://cloudsuite.ch>
   [Data Caching]: <https://github.com/ParsaLab/cloudsuite/tree/scotty/benchmarks/data-caching>
   [SPcollector]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/scotty/asset/snap/snap-plugin-collector-cloudsuite-datacaching>
   [tag-processor]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/scotty/asset/snap/snap-plugin-processor-tag>
   [influxdb-publisher]:<https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/scotty/asset/snap/snap-plugin-publisher-influxdb>
   [workload]: <https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/blob/scotty/workload.yaml>
   [Stack Config]: https://gitlab.gwdg.de/mikelangelo/cs-dataCaching/raw/scotty/asset@/stack.yaml
