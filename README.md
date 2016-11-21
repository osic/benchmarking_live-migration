Live migration in OpenStack
===========================

Table of Contents
-----------------
* [Introduction]()
* [Different ways to setup live migration in your Openstack Cloud]()
* [Benchmarking Live migration in your Cloud]()
* [Lessons learned]()

Introduction
------------
TODO: talk more on why we need live migration in the cloud. and since when It was supported in Openstack

Live migration is very usefull when a compute node goes crazy and you need to evacuate all VMs residing in it to do proper maintenance for that box. It is a key feature for high Availability of VMs which is a critical need for most bussiness applications.
 

Different ways to setup live migration in your Openstack Cloud
--------------------------------------------------------------

### Overview

To start using live migration in your cloud, First thing is to ensure is that you are using a nova hypervisor with Live migration support. Some examples are QEMU/KVM, Xen...

Now before digging deep into live migration, Here is an overview of different types of VMs One can create with Openstack.

* Boot a VM from Image: This basically creates an ephemeral disk from the chosen glance image.
* Boot a VM from Volume: Boots an instance from an existing bootable volume.
* Boot a VM from __Image (create a new volume)__: Creates a bootable volume from the image and boot instance from it.

Any VM that is booted from a volume is called volume backed VM. I would also call it a VM with remote Volume since the root disk Volume resides in another host than the compute node (the cinder volume host).

VMs with root disks being ephemeral are called block based VMs. The root disk of the VM is local to the VM itself and live on the same host as the local hypervisor managing the VM.

Now that we know how to classify different VMs in our cloud, let's take a look on the nova live migration feature and how we can use it. 

We can categorize live migration into three sets:

- Shared storage based live migration: local and remote hypervisors have access to same backend storage(e.g ceph, NFS..).
- Non shared volume storage based live migration: VMs here are volume backed and does not require shared storage.
- Non shared block live migration: VMs root disks are ephemeral image-based and does not require shared storage.

### Live migration with shared storage / Non shared volume storage

To recall, in case of shared storage, nova should have a shared storage backend typically __CEPH__ which all compute nodes can have access to. This can also be the backend for glance and cinder volumes.

For Volume storage, VMs are attached to their root disks volumes with iSCSI. To create those VMs with Openstack you can create a VM from volume, volume snapshot or Image&create new volume.

Live migration can be done through the following command

	nova live-migration { VM } { Compute-Node }

In this case, live migration will only copy the VM memory content specified above to the destination compute node.

### Live migration with block storage

This is for VMs that are created directly from an image without any backed volume.

Live migration in this case work by specifying the block-migrate parameter to the command:

	nova live-migration --block-migrate { VM } { Compute-Node }

This is because in that case vdisk content along with memory content of the  VM are copied to the destination compute machine trough a tcp connection. Obviously, this kind of live migration takes more time and can cause VM downtime.


Benchmarking Live migration in your Cloud
------------------------------------------

This section walks throuh the environment used for testing,  the process to evaluate and compare live migration both for shared storage and block storage and finally the results and findings.

### Environment
For the purpose of testing and comparaison, two production OpenStack Clouds are built with 22 nodes each using the OpenStack-ansible tool for deployment. First set of 22 nodes is using a shared storage backend based on CEPH for nova and cinder volumes. Second set is not using shared storage because volume storage live migration will be tested here. Cinder is using lvm as the Volume provider.

Each server used here has the following specifications:

    `Model:` HP DL380 Gen9
    `Processor:` 2x 12-core Intel E5-2680 v3 @ 2.50GHz
    `RAM:` 256GB RAM
    `Disk:` 12x 600GB 15K SAS - RAID10
    `NICS:` 2x Intel X710 Dual Port 10 GbE

More than that, a monitoring stack based on the TICK stack with  influx is deployed on both clouds so that we can follow in real time, metrics effected by the live migration.

### Process

 The process followed to test Live migration in both clouds is as follows:

1. Create multiple VMs in the cloud
2. Generate different kind of workloads in each VM to simulate as much as possible, a real world environment.
3. Created cronjobs in each cloud that live migrate all the VMs in one compute node to another one with a rally plugin
4. watch compare and escalate loop

### Usage

First install rally in a VM/server where you can reach your OpenStack endpoints:

	git clone https://github.com/openstack/rally.git /opt/rally
	cd /opt/rally
	sudo ./install_rally.sh

Clone the live migrator repo:

	git clone https://github.com/raddaoui/live_migrator.git
	cd live_migrator

Create a file credentials.json with you cloud information to start using rally:

	{
	    "type":"ExistingCloud",
	    "auth_url":"http://172.22.12.44:5000/v3/",
	    "endpoint_type": "internal",
	    "admin": {
	        "username": "admin",
	        "password": "***",
	        "user_domain_name": "default",
	        "project_name":"admin",
	        "project_domain_name":"default"
	    },
	    "users": [
	        {
	            "username": "admin",
	            "password": "***",
	            "project_name": "admin",
        	    "user_domain_name": "default",
	            "project_domain_name": "default"
	        }
	    ]
	}


Add a Ubuntu14.04 image:

	wget http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
	glance image-create --name 'Ubuntu 14.04 LTS' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-14.04-server-cloudimg-amd64-disk1.img
	rm ubuntu-14.04-server-cloudimg-amd64-disk1.img

Create a nova flavor:

	nova flavor-create rally.large 46  2048 80 4

Create your rally deployment and point rally to it

	rally deployment create --file=credentials.json --name=lvm_testing
	rally deployment use lvm_testing

Download the live migration plugin and task to start benchmarking Live migration:

	git clone https://github.com/raddaoui/benchmarking_live-migration_OSA.git && cd live_migrator

The live migration task downloaded will live migrage all the VMs from a compute Node to another one either specified or chosen by nova depending on the need. This task takes 5 input:

1. image_name
2. flavor_name
3. block_migration
4. host_to_evacuate
5. destination_host: if you specify nova here, destination compute host for each VM will be specified by nova.

Run the task to evacuate a compute host and start benchmarking live migration:

	rally --plugin-paths nova_live_migration.py task start task.json --task-args '{"image_name": "Ubuntu 14.04 LTS", "flavor_name": "rally.large", "block_migration": false, "host_to_evacuate": "compute03", "destination_host": "nova"}'


Optionally, you can setup cronjobs to perform last task every number of hours to start analyzing graphs from your monitoring solution:

### results and comments

Lessons learned
----------------

Below are some lessons learned while setting up the clouds to start testing live migration.

1. in your phsical compute nodes, there should be a mapping between compute hosts names and their respective local hypervisor name. Hypervisor name can be detected with the nova hypervisor-list command.

2. Cinder Volume and nova should be located in the same availability zone if you plan to live migrate volume backed VMs
