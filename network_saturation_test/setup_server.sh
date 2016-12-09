vm_name=$1
IN=$(openstack server show $1 | grep addresses | awk '{print $4}')
IFS='=' read -ra ADDR <<< "$IN"
IP=${ADDR[1]}
echo $IP
scp start-server.sh ubuntu@$IP:/home/ubuntu
ssh ubuntu@$IP '/home/ubuntu/start-server.sh'
