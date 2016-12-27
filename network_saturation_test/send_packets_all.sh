for var in "$@"
do 
  ./opt/benchmarking_live-migration/network_saturation_test/send_packets.sh $var &
done
