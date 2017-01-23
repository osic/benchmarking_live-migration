#!/usr/bin/env bash

source functions.rc
source vars.rc

cd /root
source openrc admin admin

# create the environment 
if [ `openstack flavor list | grep lm -c` -eq 0 ]; then
  nova flavor-create lm.small 7 4096 40 2 ;
  nova flavor-create lm.medium 8 8192 80 4 ;
  nova flavor-create lm.large 9 16384 160 8 ;
fi

if [ `openstack keypair list | grep $key_name -c` -eq 0 ]; then
 # openstack keypair delete $key_name
  openstack keypair create $key_name > /root/$key_name.pem
  chmod 400 /root/$key_name.pem
fi

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
cd /opt/benchmarking_live-migration/rally_lvm_plugin
rally deployment create --file=credentials.json --name=lvm_testing
rally deployment use lvm_testing

# add teh rally results to influx
rm -rf /opt/osic-reliability
git clone https://github.com/osic/osic-reliability.git /opt/osic-reliability
pip install influxdb
export INFLUXDB_HOST=$influx_ip

if [ ! -d "/opt/ops-workload-framework" ]; then git clone https://github.com/osic/ops-workload-framework.git /opt/ops-workload-framework ; fi
cd /opt/ops-workload-framework/heat_workload
python setup.py install

#install json parser for shell
apt-get install jq

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


