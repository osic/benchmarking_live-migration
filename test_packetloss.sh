    IP=$1
    fileName=$2
    echo $IP
    scp -i /root/lm_key.pem -o StrictHostKeyChecking=no ubuntu@$IP:/home/ubuntu/out.txt .
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
          echo $diff " number of packets lost during LM" $(date)>> $fileName
       fi
       previous=$current
    done <out.txt
    if $loss; then
       echo "Packet Loss during LM for VM: $IP" + $(date) 
    else
       echo "No Loss while LM for VM: $IP" +$(date) >> $fileName
    fi
    ssh -i /root/lm_key.pem ubuntu@$IP '> /home/ubuntu/out.txt'
