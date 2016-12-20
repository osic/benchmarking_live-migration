#!/bin/bash
#set -eu
# assumptions:
# network external flat is created
# clone benchmarling repo to /opt/benchmarking_live-migration and edit credentrials.json

source functions.rc

network="bc1b0934-3343-4fca-806e-3bad82205261"
key_name="lm_key"
image_name="Ubuntulm14"
influx_ip=`cat /etc/openstack_deploy/openstack_user_config.yml | grep internal_lb_vip_address | awk '{print $2}' | tr -d '"'`
stack_name="lm_test$RANDOM"
lv_results_file="/opt/lvm_results.txt"
host_to_evacuate='compute01'
destination_host='compute05'
# define workload_vms as: ( number of cpu vms, number of ram vms number of diskIO vms, number of network vms )
workloads_vms=(2-generic_cpu 0-generic_ram 0-generic_disk 0-generic_network)

environment_type[2]="heat_param_small"
environment_type[1]="heat_param_medium"
environment_type[0]="heat_param_large"


cd /root                                                                                                                                                 
source openrc admin admin 

# create the environment 
if [ `openstack flavor list | grep lm -c` -eq 0 ]; then 
  nova flavor-create lm.small 7 4096 40 2 ;
  nova flavor-create lm.medium 8 8192 80 4 ;
  nova flavor-create lm.large 9 16384 160 8 ;
fi

if [ `openstack keypair list | grep $key_name -c` -eq 1 ]; then
  openstack keypair delete $key_name
fi
openstack keypair create $key_name > /root/$key_name.pem
chmod 400 /root/$key_name.pem

# add a Ubuntu14.04 image
if [ `glance image-list | grep $image_name -c ` -eq 0 ]; then
  wget http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
  glance image-create --name $image_name \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-14.04-server-cloudimg-amd64-disk1.img
  rm ubuntu-14.04-server-cloudimg-amd64-disk1.img
fi

# setup rally and lvm rally tool
rm -rf /opt/rally
git clone https://github.com/openstack/rally.git /opt/rally
cd /opt/rally
sudo ./install_rally.sh
cd /opt/benchmarking_live-migration
rally deployment create --file=credentials.json --name=lvm_testing
rally deployment use lvm_testing

# add teh rally results to influx
rm -rf /opt/osic-reliability 
git clone https://github.com/osic/osic-reliability.git /opt/osic-reliability
pip install influxdb
export INFLUXDB_HOST=$influx_ip

#git clone https://github.com/osic/ops-workload-framework.git /opt 
cd /opt/ops-workload-framework/heat_workload
python setup.py install

sed -i '/  "flavor":/c\  "flavor": lm.small' envirnoment/heat_param_small.yaml
sed -i '/  "flavor":/c\  "flavor": lm.medium' envirnoment/heat_param_medium.yaml
sed -i '/  "flavor":/c\  "flavor": lm.large' envirnoment/heat_param_large.yaml
sed -i "/  \"network\":/c\  \"network\": $network" envirnoment/heat_param_small.yaml
sed -i "/  \"network\":/c\  \"network\": $network" envirnoment/heat_param_medium.yaml
sed -i "/  \"network\":/c\  \"network\": $network" envirnoment/heat_param_large.yaml
sed -i "/  \"key_name\":/c\  \"key_name\": $key_name" envirnoment/heat_param_small.yaml
sed -i "/  \"key_name\":/c\  \"key_name\": $key_name" envirnoment/heat_param_medium.yaml
sed -i "/  \"key_name\":/c\  \"key_name\": $key_name" envirnoment/heat_param_large.yaml
sed -i "/  \"image\":/c\  \"image\": $image_name" envirnoment/heat_param_small.yaml
sed -i "/  \"image\":/c\  \"image\": $image_name" envirnoment/heat_param_medium.yaml
sed -i "/  \"image\":/c\  \"image\": $image_name" envirnoment/heat_param_large.yaml
sed -i "/  \"influx_ip\":/c\  \"influx_ip\": $influx_ip" envirnoment/heat_param_small.yaml
sed -i "/  \"influx_ip\":/c\  \"influx_ip\": $influx_ip" envirnoment/heat_param_medium.yaml
sed -i "/  \"influx_ip\":/c\  \"influx_ip\": $influx_ip" envirnoment/heat_param_large.yaml
printf "[group_$host_to_evacuate]\n $host_to_evacuate\n" >> host


workload_def slice-destroy --name lm_slice
workload_def slice-define --name lm_slice
for i in "${workloads_vms[@]}"; do 
  for j in `seq 1 ${i%-*}`; do 
    workload_def slice-add --name lm_slice --add ${i#*-}
  done
done

#workload_def slice-add --name lm_slice --add generic_network


cd /opt/benchmarking_live-migration

for env in "${environment_type[@]}"; do
    workload_def create --slice lm_slice --name $stack_name -n 1 --group "group_$host_to_evacuate" --envt $env
    wait_instances $host_to_evacuate
    echo "All instances are up and running";
    describe_environment "${workloads_vms[*]}" $lv_results_file ${environment_type[@]##*_}

    # start the lvm tests
    sleep 25
    echo "--> evacuating all VMs from compute01 to compute05:" >> $lv_results_file
    echo "starting lvm at: `date`" >> $lv_results_file
    python test_ping_vms.py  $host_to_evacuate downtime_info.dat $lv_results_file start_tests &
    TEST_ID=$!
    rally --plugin-paths nova_live_migration.py task start task.json --task-args '{"image_name": "Ubuntulm14", "flavor_name": "lm.small", "block_migration": false, "host_to_evacuate": "compute01", "destination_host": "compute05"}'; 
    echo "finishing lvm at: `date`" >> $lv_results_file
    sleep 30
    # move VMs back
    echo "--> evacuating all VMs from comput05 to compute01:" >> $lv_results_file
    echo "starting lvm at: `date`" >> $lv_results_file
    rally --plugin-paths nova_live_migration.py task start task.json --task-args '{"image_name": "Ubuntulm14", "flavor_name": "lm.small", "block_migration": false, "host_to_evacuate": "compute05", "destination_host": "compute01"}';
    echo "finishing lvm at: `date`" >> $lv_results_file
    cat downtime_info.dat >> $lv_results_file
    python test_ping_vms.py  $host_to_evacuate downtime_info.dat $lv_results_file test_packet_loss
    kill $TEST_ID
    echo "Cleaning up"
    echo "y" | openstack stack delete $stack_name.lm_slice.$host_to_evacuate 
    break
done

#openstack stack delete lm_test.lm_slice.compute06

#for vm in `nova list | awk 'NR >2 {print $4}'`; do nova delete $vm & done;





