vm_name=$1
IN=$(openstack server show $1 | grep addresses | awk '{print $4}')
IFS='=' read -ra ADDR <<< "$IN"
IP=${ADDR[1]}
echo $IP
ssh ubuntu@$IP 'nohup sudo fuser -k 2392/tcp'
ssh ubuntu@$IP 'sudo nohup sudo nc -k -l 0.0.0.0 2392 > out.txt'  
