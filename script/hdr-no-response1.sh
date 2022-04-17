#!/bin/bash

set -e

if [ $# -ne 1 ]; then
	echo "ERROR: $(basename $0) LIN0"
	exit 1
fi

lin0=$1

shift

trap test_error_cleanup EXIT

lin0_dev_name=$(basename $lin0)
frame_count=10
log_file_path=$log_dir/hdr-no-response1_${lin0_dev_name}.log
can_dev=master

spawn_master $lin0
# echo INFO: Setting up $lin0 as master | tee -a "$meta_log_path"
# slcand -o $slcand_common_args $lin0 &
# pids+=($!)

candump $can_dev,#ffffffff -L >$log_file_path &
pids+=($!)

echo INFO: Generating $frame_count headers | tee -a "$meta_log_path"
cangen $cangen_common_args -I i -L 8 $can_dev -n $frame_count &
pids+=($!)

# brittle
sleep $candump_wait_s

lines=$(cat "$log_file_path" | wc -l)
if [ $lines -ne $frame_count ]; then
	echo ERROR: log file for master $lin0 missing messages $lines/$frame_count! | tee -a "$meta_log_path"
	errors=$((errors+1))
else
	echo INFO: log file for master $lin0 $lines/$frame_count messages OK! | tee -a "$meta_log_path"
fi



exit 0
