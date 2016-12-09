IN=$(openstack server show $1 | grep addresses | awk '{print $4}')
IFS='=' read -ra ADDR <<< "$IN"
IP=${ADDR[1]}
echo $IP
sleep 5
echo "Performing live Migration"
#nova live-migration $1 compute03 --block-migrate
sleep 10
echo "Checking packet loss"
scp -i demo.pem ubuntu@$IP:~/out .
previous=1
current=1
loss=false
while read line           
do
    current=$line
    diff=$((current-previous))
    criteria=1
    if [ "$diff" -gt "$criteria" ]; then
      loss=true
    fi
    previous=$current
done <out
sleep 5
#nova live-migration $1 compute01
if $loss; then
  echo "Packet Loss"
else
  echo "No Loss while LM"
fi

