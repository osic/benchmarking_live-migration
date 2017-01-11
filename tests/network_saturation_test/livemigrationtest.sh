./setup_server.sh test2 &
#./send_packets.sh test2
sleep 10
echo "Performing Live Migration and checking packets loss"
./send_packets.sh test2
#./test_packetloss.sh test2 compute02
