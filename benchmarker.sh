#!/bin/bash

#git clone https://github.com/osic/ops-workload-framework.git /opt
cd /opt/ops-workload-framework/heat_workload
python setup.py install
source ~/openrc admin admin

network="bc1b0934-3343-4fca-806e-3bad82205261"
key_name="tmp"
image_name="f6b10ce2-f7b9-4eed-a26b-eff7cb062fbb"
influx_ip="172.22.8.24"
stack_name="lm_test5"
flavor_type[0]="heat_param_small"
flavor_type[1]="heat_param_medium"
flavor_type[2]="heat_param_large"


nova flavor-create lm.small 7 4096 40 2
nova flavor-create lm.medium 8 8192 80 4
nova flavor-create lm.large 9 16384 160 8
openstack keypair create $key_name > tmp.pem

sed -i '/  "flavor":/c\  "flavor": lm.small' /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_small.yaml
sed -i '/  "flavor":/c\  "flavor": lm.medium' /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_medium.yaml
sed -i '/  "flavor":/c\  "flavor": lm.large' /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_large.yaml
sed -i "/  \"network\":/c\  \"network\": $network" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_small.yaml
sed -i "/  \"network\":/c\  \"network\": $network" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_medium.yaml
sed -i "/  \"network\":/c\  \"network\": $network" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_large.yaml
sed -i "/  \"key_name\":/c\  \"key_name\": $key_name" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_small.yaml
sed -i "/  \"key_name\":/c\  \"key_name\": $key_name" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_medium.yaml
sed -i "/  \"key_name\":/c\  \"key_name\": $key_name" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_large.yaml
sed -i "/  \"image_name\":/c\  \"image_name\": $image_name" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_small.yaml
sed -i "/  \"image_name\":/c\  \"image_name\": $image_name" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_medium.yaml
sed -i "/  \"image_name\":/c\  \"image_name\": $image_name" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_large.yaml
sed -i "/  \"influx_ip\":/c\  \"influx_ip\": $influx_ip" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_small.yaml
sed -i "/  \"influx_ip\":/c\  \"influx_ip\": $influx_ip" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_medium.yaml
sed -i "/  \"influx_ip\":/c\  \"influx_ip\": $influx_ip" /opt/ops-workload-framework/heat_workload/envirnoment/heat_param_large.yaml

workload_def slice-destroy --name lm_slice
workload_def slice-define --name lm_slice
workload_def slice-add --name lm_slice --add generic_cpu
workload_def slice-add --name lm_slice --add generic_cpu
workload_def slice-add --name lm_slice --add generic_ram
workload_def slice-add --name lm_slice --add generic_disk
workload_def slice-add --name lm_slice --add generic_network

echo "Environment is set up and now running the workloads"

for i in "${flavor_type[@]}"
do
    workload_def create --slice lm_slice --name $stack_name -n 1 --group group1 --envt $i
    echo "Waiting till all instances are up"
    sleep 10;
    while true; do
        n=$(openstack server list | grep -v "ACTIVE" -c)
        if [ "$n" -le 5 ]; then   break; fi
        sleep 15;
    done

    echo "All instances are up and running"
    break
done

echo "Cleaning up!!"
#openstack stack delete lm_test.lm_slice.compute06
#openstack keypair delete $key_name






