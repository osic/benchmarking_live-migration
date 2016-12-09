./setup_server.sh test2 &
./send_packets.sh test2 &
echo "Performing Live Migration and checking packets loss"
./test_packetloss.sh test2
kill $(jobs -p) 
