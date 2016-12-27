flag=true
for var in "$@"
do
    if $flag; then
       fileName=$var
       echo "FILE: " $fileName
       rm -rf "$fileName"
       flag=false
       continue
    else
       IP=$var
    fi
    echo $IP
    echo "Checking packet loss" >> "$fileName"
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
       fi
       previous=$current
    done <out.txt
    if $loss; then
       echo "Packet Loss during LM for VM: $IP" >> "$fileName"
    else
       echo "No Loss while LM for VM: $IP" >> "$fileName"
    fi
done
