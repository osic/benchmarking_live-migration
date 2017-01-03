    IP=$1
    fileName=$2
    echo $IP
    scp -i /root/lm_key.pem -o StrictHostKeyChecking=no ubuntu@$IP:/home/ubuntu/out.txt "out_$IP.txt"
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
          echo `python -c "print ($diff -1) * $3"` " seconds worth of information lost during LM for VM:  $IP" $(date)>> $fileName
       fi
       previous=$current
    done <"out_$IP.txt"
    if $loss; then
       echo "Packet Loss during LM for VM: $IP" + $(date)  >> $fileName
    else
       echo "No Loss of TCP stream and data while LM for VM: $IP" +$(date) >> $fileName
    fi
    ssh -i /root/lm_key.pem ubuntu@$IP '> /home/ubuntu/out.txt'
