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
2. create the workloads on one of the compute nodes. The workloads are basically a slice of 6 VMs: ` each VM  contains a spark cluster running a real time Spark streaming job receiving stream data at a rate of 100kB/s. each VM has its disk half full which simulate logs and data stored from apps in real world`
3. launch all the testings and measurements prior to start benchmarking live migration
4. evacuating the compute node with the workloads to another empty compute node back and forth 20 times in a row

`NOTE:` the VMS are being evacuated in series one at a time and not in parallel

This scenario will be performed against each cloud first with tunneling off and second with tunneling enabled

For each case, the scenario will run against three different flavors for its workloads: small (2 VCPUs, 4GB RAM, 40GB DISK), medium (4 VCPUs, 8GB RAM, 80GB DISK) and large(8 VCPUs, 16GB RAM, 160GB DISK)


## testings and measurements

while live migrating each VM, a number of tests is being launched to measure the performance of the live migration.

A list of the tests is listed below:

1. measure the downtime of the VM (duration of packet loss when live migrating).
2. measure the tcp stream continiousity (send packets through tcp and detect any loss).
3. measure per VM timing of live migration.
4. collect all VMs metrics while live migration (CPU, network bandwidth, disk IO, RAM).

results
-------

## Shared storage backend

#### tunneling on
     
1. flavor of workloads used is small

`Average duration to evacuate host: 3.2 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.108.166 : 3.5 seconds
    downtime for instance with ip 172.22.108.167 : 7.5 seconds
    downtime for instance with ip 172.22.108.168 : 4.0 seconds
    downtime for instance with ip 172.22.108.169 : 3.0 seconds
    downtime for instance with ip 172.22.108.171 : 6.0 seconds
    downtime for instance with ip 172.22.108.170 : 4.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.166 +Mon Feb 6 04:09:55 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.167 +Mon Feb 6 04:09:56 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.168 +Mon Feb 6 04:09:57 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.169 +Mon Feb 6 04:09:58 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.171 +Mon Feb 6 04:09:59 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.170 +Mon Feb 6 04:10:00 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 5.46666666667 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.108.160 : 2.5 seconds
    downtime for instance with ip 172.22.108.161 : 2.5 seconds
    downtime for instance with ip 172.22.108.162 : 4.0 seconds
    downtime for instance with ip 172.22.108.163 : 1.0 seconds
    downtime for instance with ip 172.22.108.164 : 3.5 seconds
    downtime for instance with ip 172.22.108.165 : 4.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.160 +Sun Feb 5 19:11:49 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.161 +Sun Feb 5 19:11:50 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.162 +Sun Feb 5 19:11:51 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.163 +Sun Feb 5 19:11:52 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.164 +Sun Feb 5 19:11:53 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.165 +Sun Feb 5 19:11:54 CST 2017

3. flavor of workloads used is large

`Average duration of live migration: 9.51666666667 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.108.155 : 3.5 seconds
    downtime for instance with ip 172.22.108.154 : 2.5 seconds
    downtime for instance with ip 172.22.108.157 : 4.5 seconds
    downtime for instance with ip 172.22.108.156 : 4.5 seconds
    downtime for instance with ip 172.22.108.159 : 3.0 seconds
    downtime for instance with ip 172.22.108.158 : 2.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.155 +Sun Feb 5 05:47:52 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.154 +Sun Feb 5 05:47:54 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.157 +Sun Feb 5 05:47:56 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.156 +Sun Feb 5 05:47:58 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.159 +Sun Feb 5 05:47:59 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.158 +Sun Feb 5 05:48:06 CST 2017

#### tunneling off

1. flavor of workloads used is small

`Average duration of live migration: 1.73333333333`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.108.133 : 4.5 seconds
    downtime for instance with ip 172.22.108.132 : 6.5 seconds
    downtime for instance with ip 172.22.108.131 : 6.0 seconds
    downtime for instance with ip 172.22.108.130 : 5.5 seconds
    downtime for instance with ip 172.22.108.135 : 6.5 seconds
    downtime for instance with ip 172.22.108.134 : 3.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.133 +Thu Feb 2 20:40:02 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.132 +Thu Feb 2 20:40:03 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.131 +Thu Feb 2 20:40:04 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.130 +Thu Feb 2 20:40:05 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.135 +Thu Feb 2 20:40:06 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.134 +Thu Feb 2 20:40:07 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 2.7 minutes minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.108.151 : 5.5 seconds
    downtime for instance with ip 172.22.108.150 : 2.5 seconds
    downtime for instance with ip 172.22.108.153 : 6.0 seconds
    downtime for instance with ip 172.22.108.152 : 6.0 seconds
    downtime for instance with ip 172.22.108.148 : 7.0 seconds
    downtime for instance with ip 172.22.108.149 : 6.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.151 +Sat Feb 4 12:52:17 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.150 +Sat Feb 4 12:52:18 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.153 +Sat Feb 4 12:52:19 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.152 +Sat Feb 4 12:52:20 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.148 +Sat Feb 4 12:52:21 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.149 +Sat Feb 4 12:52:22 CST 2017

3. flavor of workloads used is large

`Average duration of live migration: 1.98333333333 minutes`

`live migration success rate = 233/240`

    downtime for instance with ip 172.22.108.146 : 3.5 seconds
    downtime for instance with ip 172.22.108.147 : 5.5 seconds
    downtime for instance with ip 172.22.108.144 : 3.0 seconds
    downtime for instance with ip 172.22.108.145 : 2.5 seconds
    downtime for instance with ip 172.22.108.142 : 5.5 seconds
    downtime for instance with ip 172.22.108.143 : 3.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.108.146 +Fri Feb 3 17:37:57 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.147 +Fri Feb 3 17:37:58 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.144 +Fri Feb 3 17:37:59 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.145 +Fri Feb 3 17:38:00 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.142 +Fri Feb 3 17:38:00 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.108.143 +Fri Feb 3 17:38:01 CST 2017

## local storage backend

#### tunneling on

1. flavor of workloads used is small

`Average duration of live migration: 6.48333333333 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.148.60 : 8.0 seconds
    downtime for instance with ip 172.22.148.64 : 4.0 seconds
    downtime for instance with ip 172.22.148.66 : 4.5 seconds
    downtime for instance with ip 172.22.148.67 : 10.5 seconds
    downtime for instance with ip 172.22.148.57 : 7.5 seconds
    downtime for instance with ip 172.22.148.56 : 10.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.60 +Mon Feb 6 06:15:57 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.64 +Mon Feb 6 06:15:58 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.66 +Mon Feb 6 06:15:58 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.67 +Mon Feb 6 06:15:59 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Mon Feb 6 06:16:00 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Mon Feb 6 06:16:01 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 12.4833333333 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.148.63 : 4.5 seconds
    downtime for instance with ip 172.22.148.67 : 34.5 seconds
    downtime for instance with ip 172.22.148.68 : 5.5 seconds
    downtime for instance with ip 172.22.148.53 : 3.5 seconds
    downtime for instance with ip 172.22.148.54 : 30.5 seconds
    downtime for instance with ip 172.22.148.57 : 8.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.63 +Sun Feb 5 23:48:48 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.67 +Sun Feb 5 23:48:49 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.68 +Sun Feb 5 23:48:50 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.53 +Sun Feb 5 23:48:51 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.54 +Sun Feb 5 23:48:52 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Sun Feb 5 23:48:52 CST 2017

3. flavor of workloads used is large

`NOTE:` 1 VM failed to live migration in the 17th iteration

`Average duration of live migration: 2.06666666667 minutes`

`live migration success rate = 234/240`

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

`Average duration of live migration: 6.7 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.148.59 : 16.5 seconds
    downtime for instance with ip 172.22.148.62 : 5.5 seconds
    downtime for instance with ip 172.22.148.64 : 7.0 seconds
    downtime for instance with ip 172.22.148.65 : 25.5 seconds
    downtime for instance with ip 172.22.148.66 : 40.5 seconds
    downtime for instance with ip 172.22.148.68 : 18.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.59 +Fri Feb 3 01:35:40 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.62 +Fri Feb 3 01:35:42 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.64 +Fri Feb 3 01:35:43 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.65 +Fri Feb 3 01:35:45 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.66 +Fri Feb 3 01:35:47 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.68 +Fri Feb 3 01:35:48 CST 2017

2. flavor of workloads used is medium

`Average duration of live migration: 12.3 minutes`

`live migration success rate = 240/240`

    downtime for instance with ip 172.22.148.60 : 3.0 seconds
    downtime for instance with ip 172.22.148.58 : 56.0 seconds
    downtime for instance with ip 172.22.148.62 : 14.5 seconds
    downtime for instance with ip 172.22.148.53 : 4.0 seconds
    downtime for instance with ip 172.22.148.55 : 1.0 seconds
    downtime for instance with ip 172.22.148.54 : 26.5 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.60 +Sat Feb 4 19:23:20 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.58 +Sat Feb 4 19:23:21 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.62 +Sat Feb 4 19:23:22 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.53 +Sat Feb 4 19:23:23 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.55 +Sat Feb 4 19:23:24 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.54 +Sat Feb 4 19:23:25 CST 2017

3. flavor of workloads used is large

`Average duration of live migration: 24.0166666667  minutes`

`live migration success rate = 239/240`

    downtime for instance with ip 172.22.148.59 : 6.0 seconds
    downtime for instance with ip 172.22.148.62 : 3.5 seconds
    downtime for instance with ip 172.22.148.66 : 7.5 seconds
    downtime for instance with ip 172.22.148.55 : 6.0 seconds
    downtime for instance with ip 172.22.148.57 : 4.5 seconds
    downtime for instance with ip 172.22.148.56 : 6.0 seconds

    No Loss of TCP stream and data while LM for VM: 172.22.148.59 +Sat Feb 4 06:14:00 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.62 +Sat Feb 4 06:14:02 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.66 +Sat Feb 4 06:14:04 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.55 +Sat Feb 4 06:14:06 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.57 +Sat Feb 4 06:14:07 CST 2017
    No Loss of TCP stream and data while LM for VM: 172.22.148.56 +Sat Feb 4 06:14:09 CST 2017

Conclusion&Lessons learned
--------------------------

1. with large flavors some failures were recorded to live migrate. Debugging those, lead to two findings

  - some VMs were failing because live migration timeout was reached. Setting this value (live_migration_progress_timeout) to zero(infinity) lead to 100% success rate for the shared storage case.

  - Some VMs fail to live migrate because nova failed to update the VM status after migrating. debugging is still ongoing

2. when using live migration with tunneling off, live migration will be done in the hypervisor level, that's why hypervisor should be able to resolve the different hypervisor names in the cloud. To fix that, in the physical compute nodes, there should be a mapping between compute hosts names or ips with their respective local hypervisor name. Hypervisor name can be detected with the nova hypervisor-list command.

3. Cinder Volume and nova should be located in the same availability zone if you plan to live migrate volume backed VMs

4. Tunneling disabling reduce Live migration duration 

5. No TCP stream loss was recorded for all tests

