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
frame_count=9
dev_log_file_path=$log_dir/hdr-no-response1_${lin0_dev_name}.log
expect_log_file_path=$log_dir/hdr-no-response1_expect.log
can_dev=master
errors=0

for i in $(seq 0 $((frame_count-1))); do
	printf "dummy dummy 08%x#R\n" $i >>$expect_log_file_path
done
# cat $expect_log_file_path


spawn_master $lin0


candump $can_dev,#ffffffff -L >$dev_log_file_path &
pids+=($!)

echo INFO: Generating $frame_count headers | tee -a "$meta_log_path"
cangen $cangen_common_args -R -I i -L i $can_dev -n $frame_count &
pids+=($!)

# brittle
sleep $candump_wait_s

lines=$(cat "$dev_log_file_path" | wc -l)
if [ $lines -ne $frame_count ]; then
	echo ERROR: log file for master $lin0 missing messages $lines/$frame_count! | tee -a "$meta_log_path"
	errors=$((errors+1))
else
	echo INFO: log file for master $lin0 $lines/$frame_count messages OK! | tee -a "$meta_log_path"
fi


set +e

echo INFO: Comparing received frames against expected | tee -a "$meta_log_path"
same_messages $expect_log_file_path $dev_log_file_path 3
if [ $? -ne 0 ]; then
	echo ERROR: $lin0 messages DIFFER from expected! | tee -a "$meta_log_path"
	errors=$((errors+1))
else
	echo INFO: $lin0 messages OK! | tee -a "$meta_log_path"
fi

set -e

exit $errors
