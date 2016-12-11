server_name=$1
node=$2
IN=$(openstack server show $1 | grep addresses | awk '{print $4}')
IFS='=' read -ra ADDR <<< "$IN"
IP=${ADDR[1]}
echo $IP
influx_ip='172.22.8.24'
ssh ubuntu@$IP "sudo sed -i '1s/^/nameserver 8.8.8.8 /' /etc/resolv.conf;sudo apt-get -y dist-upgrade;sudo apt-get -y update;sudo apt-get -y install git;sudo wget https://dl.influxdata.com/telegraf/releases/telegraf_1.0.1_amd64.deb;sudo dpkg -i telegraf_1.0.1_amd64.deb;sudo telegraf config > /etc/telegraf/telegraf.conf;sudo sed -i -e 's/localhost/$influx_ip/g' /etc/telegraf/telegraf.conf;sudo service telegraf restart"
echo "Wait to capture the metrics from VM"
sleep 10
nova live-migration $server_name $node
echo "VM $1 migrated to $node"
