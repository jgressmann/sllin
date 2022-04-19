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
frame_count=63
dev_log_file_path=$log_dir/set-response_actual_${lin0_dev_name}.log
errors=0

# max timeout
spawn_slave $lin0 -s 6


candump $lin0_dev_name,#ffffffff -L >$dev_log_file_path 2>/dev/null &
candump_pid=$!
pids+=($candump_pid)

echo INFO: Generating set response frames | tee -a "$meta_log_path"
cangen $cangen_common_args -I i -L i -D i $lin0_dev_name -n $frame_count &
cangen_pid=$!
pids+=($cangen_pid)

# brittle
sleep $candump_wait_s

friendly_kill $cangen_pid
friendly_kill $candump_pid

lines=$(cat "$dev_log_file_path" | wc -l)
if [ $lines -ne 0 ]; then
	echo ERROR: unexpected response from slave $lin0_dev_name | tee -a "$meta_log_path"
	errors=$((errors+1))
else
	echo INFO: responses set OK! | tee -a "$meta_log_path"
fi



exit $errors
