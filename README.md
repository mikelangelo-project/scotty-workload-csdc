CloudSuite Data Caching benchmark workload
------------------------------------------


[![N|Solid](https://www.gwdg.de/GWDG-Theme-1.0-SNAPSHOT/images/gwdg_logo.svg)](https://nodesource.com/products/nsolid)



Overview
--------

Cloudsuite is a benchmark suite for cloud service. This implementation aims to run a Data Caching benchmark on multiple server using overlay network on docker swarm over Openstack Cloud. It is possible to run the benchmark either On OpneStack cloud or Virtual machine. The difference between these two is that, in OpneStack everything would be run automatically, from creating virtual machines to running the benchmark, however in virtual machine mode, you need to create machines by your self and then run scripts manually on each of virtual machines.

Requirements
----------

This workload only works with OpenStack Swarm resource.
use ``asset/stack.yaml`` as stack configuration file.

Parameters
----------

list of all parameters available on ``workload.yaml``