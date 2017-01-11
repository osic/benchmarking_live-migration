#!/usr/bin/env bash
source functions.rc
source vars.rc

cd /root
source openrc admin admin

# Destroy workload stack if there is any
workload_def slice-destroy --name lm_slice
workload_def slice-define --name lm_slice

# add Workloads to the slice
for i in "${workloads_vms[@]}"; do
  for j in `seq 1 ${i%-*}`; do
    workload_def slice-add --name lm_slice --add ${i#*-}
  done
done

cd /opt/benchmarking_live-migration
echo '' > $lv_results_file
get_specs_server $host_to_evacuate | sed -e '1,/start/d' >> $lv_results_file
get_specs_server $destination_host | sed -e '1,/start/d' >>  $lv_results_file

for env in "${environment_type[@]}"; do
    cat /opt/ops-workload-framework/heat_workload/envirnoment/$env.yaml
    if [ $DEPLOY_WORKLOADS == TRUE ]; then
      workload_def create --slice lm_slice --name $stack_name -n 1 --group "group_$host_to_evacuate" --envt $env
      wait_instances $host_to_evacuate
      echo "All instances are up and running";
      describe_environment "${workloads_vms[*]}" $lv_results_file ${environment_type[@]##*_}
      echo "Waiting for 60 seconds before running the tests"
      sleep 10
      # start the lvm tests
    fi
    DATE=`date +%Y-%m-%d`
    TIME=`date +%H:%M`
    time="$DATE $TIME"
    python tests/test_ping_vms.py  $host_to_evacuate $downtime_info $lv_results_file start_tests &
    TEST_ID=$!
    for itr in `seq 0 $ITERATIONS`; do
      echo "--> evacuating all VMs from $host_to_evacuate to $destination_host ITERATION n: $itr" | tee -a $lv_results_file
      echo "starting lvm at: `date`" | tee -a $lv_results_file
      rallytask_arg="'{\"image_name\": \"Ubuntulm14\", \"flavor_name\":\"lm.small\", \"block_migration\": false, \"host_to_evacuate\": \"$host_to_evacuate\", \"destination_host\": \"$destination_host\"}'"
      echo "rally --plugin-paths rally_lvm_plugin/nova_live_migration.py task start rally_lvm_plugin/task.json --task-args $rallytask_arg; python /opt/osic-reliability/monitoring/send_task_data_to_influx.py" | bash
      echo "finishing lvm at: `date`" | tee -a $lv_results_file
      servers=`python tests/test_ping_vms.py "$host_to_evacuate" $downtime_info dfd get_servers`
      if [ "$servers" != "{}" ]; then
        echo "$servers failed to migrate from $host_to_evacuate" >> $lv_results_file
        break;
      fi
      
      # move VMs back
      sleep 10
      echo "--> evacuating all VMs from $destination_host to $host_to_evacuate:" | tee -a $lv_results_file
      echo "starting lvm at: `date`" | tee -a $lv_results_file
      rallytask_arg="'{\"image_name\": \"Ubuntulm14\", \"flavor_name\":\"lm.small\", \"block_migration\": false, \"host_to_evacuate\": \"$destination_host\", \"destination_host\": \"$host_to_evacuate\"}'"
      echo "rally --plugin-paths rally_lvm_plugin/nova_live_migration.py task start rally_lvm_plugin/task.json --task-args $rallytask_arg; python /opt/osic-reliability/monitoring/send_task_data_to_influx.py" | bash
      echo "finishing lvm at: `date`" | tee -a $lv_results_file
      servers=`python tests/test_ping_vms.py "$destination_host" $downtime_info dfd get_servers`
      if [ "$servers" != "{}" ]; then
        echo "$servers failed to migrate from $destination_host" >> $lv_results_file
        break;
      fi;
      sleep 10
    done
    cat $downtime_info >> $lv_results_file
    python test_ping_vms.py  $host_to_evacuate $downtime_info $lv_results_file test_packet_loss
    
    log1="$host_to_evacuate"_compute.log
    log2="$destination_host"_compute.log
    scp $host_to_evacuate:/var/log/nova/nova-compute.log /tmp/
    cat /tmp/nova-compute.log | grep "$time" -A 100000 > /opt/$log1
    scp $destination_host:/var/log/nova/nova-compute.log /tmp/
    cat /tmp/nova-compute.log | grep "$time" -A 100000 > /opt/$log2
    rm -rf /tmp/nova-compute.log
    kill $TEST_ID
    echo "Cleaning up Resources.."
##    echo "y" | openstack stack delete $stack_name.lm_slice.$host_to_evacuate

    break;
done
