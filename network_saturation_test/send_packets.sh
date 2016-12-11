IN=$(openstack server show $1 | grep addresses | awk '{print $4}')
IFS='=' read -ra ADDR <<< "$IN"
IP=${ADDR[1]}  
echo $IP
counter=0
(while true
do
  counter=$((counter+1))
  echo $counter
done) | nc $IP 2392
