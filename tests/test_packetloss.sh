#!/usr/bin/env bash

function measure_tcp_loss() {
python <<EOL
filename = "$1"
loss = 0
f = open(filename,'rwb')
l = f.read()
numbers = filter(lambda x: x.isdigit(), l.split('\n'))
previous = int(numbers[0])
for i in numbers[1:]:
  diff = int(i) - previous
  if (diff > 1):
    loss += (diff - 1)
  previous = int(i)
print loss
EOL
}

IP=$1
fileName=$2
scp -i /root/lm_key.pem -o StrictHostKeyChecking=no ubuntu@$IP:/home/ubuntu/out.txt "/tmp/out_$IP.txt"
loss=`measure_tcp_loss /tmp/out_$IP.txt` 

if [ "$loss" -eq "0" ]; then
  echo "No Loss of TCP stream and data while LM for VM: $IP" +$(date) | tee -a $fileName
else
  echo `python -c "print (int($loss) * $3)"` " seconds worth of information lost of TCP stream during LM for VM:  $IP" | tee -a $fileName
fi

ssh -i /root/lm_key.pem -o StrictHostKeyChecking=no ubuntu@$IP << 'EOF'
  sudo su
  pc=$(ps aux | grep nc | grep 2392 | awk '{print $2}')
  kill -9 $pc
  rm -f /home/ubuntu/out.txt
  touch /home/ubuntu/out.txt
  chmod 777 /home/ubuntu/out.txt
  nohup nc -d -l -k 0.0.0.0 2392 > /home/ubuntu/out.txt 2>&1 &
EOF
