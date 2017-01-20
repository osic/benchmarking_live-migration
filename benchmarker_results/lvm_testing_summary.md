Live migration benchmarking for OpenStack
==========================================

Environment
------------

For the purpose of testing and comparaison, two production OpenStack Clouds are built using OpenStack-ansible tool for deployment:

1. 22 nodes-Cloud with a shared storage backend based on CEPH for nova and cinder volumes.

2. 22 nodes-CLoud Second with local storage. Cinder is using lvm as the Volume provider.

Each node has the following specifications:

    Model: HP DL380 Gen9
    Processor: 2x 12-core Intel E5-2680 v3 @ 2.50GHz
    RAM: 256GB RAM
    Disk: 12x 600GB 15K SAS - RAID10
    NICS: 2x Intel X710 Dual Port 10 GbE

More than that, a monitoring stack based on the TICK stack with  influx is deployed on both clouds so that we can follow in real time, metrics effected by the live migration.

Testing methodology
---------------------

## test Scenarios

To benchmark live migration, a tool has been put in place. This tool will

1. Bootstrap the Openstack Cloud for live migration testing: create images, keys, flavors.. install rally and workload generator.
2. create the workloads on one of the compute nodes. The workloads are basically a slice of 6 VMs: 5 VMs each one contains a spark cluster running a real time Spark streaming job while the 6th VM is a client that feeds data to the other nodes containing the spark workers. `The client is sending stream data at a rate of 1MB/s to each spark node.`
3. launch all the testings and measurements prior to start benchmarking live migration
4. evacuating the compute node with the workloads to another empty compute node back and forth 30 times in a row

`NOTE:` the VMS are being evacuated in series one at a time and not in parallel

This scenario will be performed against each cloud first with tunneling off and second with tunneling enabled

For each case, the scenario will run against three different flavors for its workloads: small (2 VCPUs, 4GB RAM, 40GB DISK), medium (4 VCPUs, 8GB RAM, 80GB DISK) and large(8 VCPUs, 16GB RAM, 160GB DISK)


## testings and measurements

while live migrating each VM, a number of tests is being launched to measure the performance of the live migration.

A list of the tests is listed below:

1. measure the downtime of the VM (duration of packet loss when live migrating).
2. measure the tcp stream continiousity (send packets through tcp and detect any loss).
3. measure the timing to evacuate the compute node.
4. collect all VMs metrics while live migration (CPU, network bandwidth, disk IO, RAM).

results
-------

## Shared storage backend

#### tunneling on
     
1. flavor of workloads used is small

`Average duration of live migration: 1.93333333333 minutes`

    downtime for instance with ip 172.22.108.249 : 5.5 seconds
    downtime for instance with ip 172.22.108.248 : 2.0 seconds
    downtime for instance with ip 172.22.108.247 : 6.0 seconds
    downtime for instance with ip 172.22.108.252 : 6.0 seconds
    downtime for instance with ip 172.22.108.250 : 7.5 seconds
    downtime for instance with ip 172.22.108.251 : 7.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.249 +Mon Jan 16 23:02:20 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.248 +Mon Jan 16 23:02:20 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.247 +Mon Jan 16 23:02:21 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.252 +Mon Jan 16 23:02:21 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.250 +Mon Jan 16 23:02:22 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.251 +Mon Jan 16 23:02:22 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 2.11666666667 minutes`

    downtime for instance with ip 172.22.108.245 : 4.0 seconds
    downtime for instance with ip 172.22.108.244 : 4.0 seconds
    downtime for instance with ip 172.22.108.246 : 5.0 seconds
    downtime for instance with ip 172.22.108.241 : 6.5 seconds
    downtime for instance with ip 172.22.108.243 : 3.5 seconds
    downtime for instance with ip 172.22.108.242 : 4.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.245 +Mon Jan 16 20:44:32 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.244 +Mon Jan 16 20:44:32 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.246 +Mon Jan 16 20:44:33 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.241 +Mon Jan 16 20:44:34 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.243 +Mon Jan 16 20:44:34 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.242 +Mon Jan 16 20:44:35 CST 2017

3. flavor of workloads used is large

`Average duration of live migration: 3.98333333333 minutes`

    downtime for instance with ip 172.22.108.210 : 7.0 seconds
    downtime for instance with ip 172.22.108.205 : 6.5 seconds
    downtime for instance with ip 172.22.108.207 : 6.0 seconds
    downtime for instance with ip 172.22.108.206 : 7.0 seconds
    downtime for instance with ip 172.22.108.209 : 4.5 seconds
    downtime for instance with ip 172.22.108.208 : 4.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.210 +Sun Jan 15 22:19:06 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.205 +Sun Jan 15 22:19:07 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.207 +Sun Jan 15 22:19:07 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.206 +Sun Jan 15 22:19:08 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.209 +Sun Jan 15 22:19:09 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.208 +Sun Jan 15 22:19:10 CST 2017

#### tunneling off

1. flavor of workloads used is small

`Average duration of live migration: 1.35 minutes`

    downtime for instance with ip 172.22.108.102 : 4.5 seconds
    downtime for instance with ip 172.22.108.103 : 5.0 seconds
    downtime for instance with ip 172.22.108.101 : 8.0 seconds
    downtime for instance with ip 172.22.108.106 : 4.5 seconds
    downtime for instance with ip 172.22.108.104 : 7.5 seconds
    downtime for instance with ip 172.22.108.105 : 6.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.102 +Tue Jan 17 17:24:02 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.103 +Tue Jan 17 17:24:03 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.101 +Tue Jan 17 17:24:03 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.106 +Tue Jan 17 17:24:04 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.104 +Tue Jan 17 17:24:04 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.105 +Tue Jan 17 17:24:05 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 1.26666666667 minutes`

    downtime for instance with ip 172.22.108.108 : 4.0 seconds
    downtime for instance with ip 172.22.108.109 : 8.0 seconds
    downtime for instance with ip 172.22.108.111 : 7.5 seconds
    downtime for instance with ip 172.22.108.110 : 6.0 seconds
    downtime for instance with ip 172.22.108.112 : 7.0 seconds
    downtime for instance with ip 172.22.108.107 : 5.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.108 +Tue Jan 17 20:09:27 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.109 +Tue Jan 17 20:09:27 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.111 +Tue Jan 17 20:09:28 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.110 +Tue Jan 17 20:09:29 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.112 +Tue Jan 17 20:09:29 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.107 +Tue Jan 17 20:09:30 CST 2017

3. flavor of workloads used is large

`Average duration of live migration: 1.98333333333 minutes`

    downtime for instance with ip 172.22.108.118 : 5.5 seconds
    downtime for instance with ip 172.22.108.113 : 1.5 seconds
    downtime for instance with ip 172.22.108.115 : 6.0 seconds
    downtime for instance with ip 172.22.108.114 : 5.5 seconds
    downtime for instance with ip 172.22.108.117 : 7.5 seconds
    downtime for instance with ip 172.22.108.116 : 3.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.118 +Tue Jan 17 22:30:21 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.113 +Tue Jan 17 22:30:22 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.115 +Tue Jan 17 22:30:23 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.114 +Tue Jan 17 22:30:23 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.117 +Tue Jan 17 22:30:24 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.116 +Tue Jan 17 22:30:25 CST 2017


## local storage backend

#### tunneling on

1. flavor of workloads used is small

`Average duration of live migration: 1.45 minutes`

    downtime for instance with ip 172.22.148.59 : 1.0 seconds
    downtime for instance with ip 172.22.148.58 : 4.5 seconds
    downtime for instance with ip 172.22.148.62 : 3.0 seconds
    downtime for instance with ip 172.22.148.61 : 3.0 seconds
    downtime for instance with ip 172.22.148.57 : 5.5 seconds
    downtime for instance with ip 172.22.148.56 : 5.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.59 +Thu Jan 19 01:20:00 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.58 +Thu Jan 19 01:20:01 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.62 +Thu Jan 19 01:20:03 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.61 +Thu Jan 19 01:20:04 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Thu Jan 19 01:20:05 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Thu Jan 19 01:20:06 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 1.51666666667 minutes`

    downtime for instance with ip 172.22.148.61 : 8.0 seconds
    downtime for instance with ip 172.22.148.62 : 6.5 seconds
    downtime for instance with ip 172.22.148.58 : 5.0 seconds
    downtime for instance with ip 172.22.148.55 : 7.0 seconds
    downtime for instance with ip 172.22.148.57 : 7.5 seconds
    downtime for instance with ip 172.22.148.56 : 5.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.61 +Thu Jan 19 12:13:53 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.62 +Thu Jan 19 12:13:54 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.58 +Thu Jan 19 12:13:55 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.55 +Thu Jan 19 12:13:55 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Thu Jan 19 12:13:56 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Thu Jan 19 12:13:57 CST 2017

3. flavor of workloads used is large

`NOTE:` 1 VM failed to live migration in the 17th iteration

`Average duration of live migration: 2.06666666667 minutes`

    downtime for instance with ip 172.22.148.60 : 4.0 seconds 
    downtime for instance with ip 172.22.148.62 : 4.0 seconds 
    downtime for instance with ip 172.22.148.66 : 3.5 seconds 
    downtime for instance with ip 172.22.148.55 : 4.0 seconds 
    downtime for instance with ip 172.22.148.57 : 5.0 seconds 
    downtime for instance with ip 172.22.148.56 : 3.0 seconds 

    No Loss of TCP stream and data while LM for VM: 172.22.148.60 +Thu Jan 19 13:38:17 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.55 +Thu Jan 19 13:38:17 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Thu Jan 19 13:38:18 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.66 +Thu Jan 19 13:38:19 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Thu Jan 19 13:38:19 CST 2017

#### tunneling off

1. flavor of workloads used is small

`Average duration of live migration: 1.43333333333 minutes`

    downtime for instance with ip 172.22.148.59 : 3.0 seconds
    downtime for instance with ip 172.22.148.61 : 6.5 seconds
    downtime for instance with ip 172.22.148.64 : 4.0 seconds
    downtime for instance with ip 172.22.148.58 : 4.5 seconds
    downtime for instance with ip 172.22.148.53 : 5.5 seconds
    downtime for instance with ip 172.22.148.56 : 6.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.59 +Wed Jan 18 19:32:59 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.61 +Wed Jan 18 19:33:00 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.64 +Wed Jan 18 19:33:01 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.58 +Wed Jan 18 19:33:01 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.53 +Wed Jan 18 19:33:02 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Wed Jan 18 19:33:02 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 1.5 minutes`

    downtime for instance with ip 172.22.148.60 : 7.0 seconds
    downtime for instance with ip 172.22.148.61 : 3.5 seconds
    downtime for instance with ip 172.22.148.55 : 6.5 seconds
    downtime for instance with ip 172.22.148.54 : 9.0 seconds
    downtime for instance with ip 172.22.148.57 : 3.0 seconds
    downtime for instance with ip 172.22.148.56 : 5.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.60 +Wed Jan 18 17:11:34 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.61 +Wed Jan 18 17:11:34 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.55 +Wed Jan 18 17:11:35 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.54 +Wed Jan 18 17:11:36 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Wed Jan 18 17:11:36 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Wed Jan 18 17:11:37 CST 2017

3. flavor of workloads used is large

`NOTE:` 2 VMs failed to live migration in the forth iteration

`Average duration of live migration: 1.48333333333 minutes`

    downtime for instance with ip 172.22.148.60 : 0.5 seconds
    downtime for instance with ip 172.22.148.61 : 1.0 seconds
    downtime for instance with ip 172.22.148.62 : 1.0 seconds
    downtime for instance with ip 172.22.148.53 : 0 seconds
    downtime for instance with ip 172.22.148.54 : 1.5 seconds
    downtime for instance with ip 172.22.148.57 : 0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.54 +Wed Jan 18 14:52:20 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Wed Jan 18 14:52:21 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.53 +Wed Jan 18 14:52:22 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.62 +Wed Jan 18 14:52:22 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.60 +Wed Jan 18 14:52:23 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.61 +Wed Jan 18 14:52:24 CST 2017

Lessons learned
----------------

1. when using live migration with tunneling off, live migration will be done in the hypervisor level, that's why hypervisor should be able to resolve the different hypervisor names in the cloud. To fix that, in the phsical compute nodes, there should be a mapping between compute hosts names or ips with their respective local hypervisor name. Hypervisor name can be detected with the nova hypervisor-list command.

2. Cinder Volume and nova should be located in the same availability zone if you plan to live migrate volume backed VMs

3. Tunneling disabling reduce Live migration duration 

4. No TCP stream loss was recorded for all tests

5. testing was performed with spark streaming nodes processing data with a batch dration of 2 seconds. Putting that value to 1 second failed most of the live migration tests.
