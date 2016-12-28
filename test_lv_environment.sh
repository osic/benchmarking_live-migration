#!/usr/bin/env bash
source functions.rc
source vars.rc

cd /root
source openrc admin admin

cd /opt/benchmarking_live-migration
echo '' > $lv_results_file
get_specs_server $host_to_evacuate | sed -e '1,/start/d' >> $lv_results_file
get_specs_server $destination_host | sed -e '1,/start/d' >>  $lv_results_file

for env in "${environment_type[@]}"; do
    cat /opt/ops-workload-framework/heat_workload/envirnoment/$env.yaml
    workload_def create --slice lm_slice --name $stack_name -n 1 --group "group_$host_to_evacuate" --envt $env
    wait_instances $host_to_evacuate
    echo "All instances are up and running";
    describe_environment "${workloads_vms[*]}" $lv_results_file ${environment_type[@]##*_}
    # start the lvm tests
    sleep 25
    echo "--> evacuating all VMs from $host_to_evacuate to $destination_host:" >> $lv_results_file
    echo "Saving logs of $host_to_evacuate and $destination_host nodes"
    time=$(echo $(ssh $host_to_evacuate 'tail -n 1 /var/log/nova/nova-compute.log') | awk -F ' ' '{print $1" "$2}' | awk -F '.' '{ print $1}' | awk -F ':' '{ print $1 ":"$2}' )
    echo "starting lvm at: `date`" >> $lv_results_file
    python test_ping_vms.py  $host_to_evacuate downtime_info.dat $lv_results_file start_tests &
    TEST_ID=$!
    rally --plugin-paths nova_live_migration.py task start task.json --task-args '{"image_name": "Ubuntulm14", "flavor_name": "lm.small", "block_migration": false, "host_to_evacuate": "compute01", "destination_host": "compute05"}'; python /opt/osic-reliability/monitoring/send_task_data_to_influx.py
    echo "finishing lvm at: `date`" >> $lv_results_file
    servers=`python test_ping_vms.py "$host_to_evacuate" downtime_info.dat dfd get_servers`
    if [ "$servers" != "{}" ]; then
      echo "$servers failed to migrate from $host_to_evacuate" >> $lv_results_file
    fi
    sleep 30
    # move VMs back
    echo "--> evacuating all VMs from $destination_host to $host_to_evacuate:" >> $lv_results_file
    echo "starting lvm at: `date`" >> $lv_results_file
    rally --plugin-paths nova_live_migration.py task start task.json --task-args '{"image_name": "Ubuntulm14", "flavor_name": "lm.small", "block_migration": false, "host_to_evacuate": "compute05", "destination_host": "compute01"}'; python /opt/osic-reliability/monitoring/send_task_data_to_influx.py
    echo "finishing lvm at: `date`" >> $lv_results_file
    servers=`python test_ping_vms.py "$destination_host" downtime_info.dat dfd get_servers`
    if [ "$servers" != "{}" ]; then
      echo "$servers failed to migrate from $destination_host" >> $lv_results_file
    fi
    cat downtime_info.dat >> $lv_results_file
    python test_ping_vms.py  $host_to_evacuate downtime_info.dat $lv_results_file test_packet_loss
    
    scp $host_to_evacuate:/var/log/nova/nova-compute.log .
    log1="$host_to_evacuate"_compute.log
    log2="$destination_host"_compute.log
    cat nova-compute.log | grep "$time" -A 100000 > $log1
    scp $destination_host:/var/log/nova/nova-compute.log .
    cat nova-compute.log | grep "$time" -A 100000 > $log2
    rm -rf nova-compute.log
    kill $TEST_ID
    echo "Cleaning up Resources.."
##    echo "y" | openstack stack delete $stack_name.lm_slice.$host_to_evacuate
    break;
done
