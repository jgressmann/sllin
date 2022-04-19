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
dev_log_file_path=$log_dir/master-tx_actual_${lin0_dev_name}.log
expect_log_file_path=$log_dir/master-tx_expect_${lin0_dev_name}.log
errors=0

cat <<EOF | awk '{print "data interface " $0}' >$expect_log_file_path
400#00
401#01
402#0200
403#030000
404#04000000
405#0500000000
406#060000000000
407#07000000000000
408#0800000000000000
409#09
40A#0A
40B#0B00
40C#0C0000
40D#0D000000
40E#0E00000000
40F#0F0000000000
410#10000000000000
411#1100000000000000
412#12
413#13
414#1400
415#150000
416#16000000
417#1700000000
418#180000000000
419#19000000000000
41A#1A00000000000000
41B#1B
41C#1C
41D#1D00
41E#1E0000
41F#1F000000
420#2000000000
421#210000000000
422#22000000000000
423#2300000000000000
424#24
425#25
426#2600
427#270000
428#28000000
429#2900000000
42A#2A0000000000
42B#2B000000000000
42C#2C00000000000000
42D#2D
42E#2E
42F#2F00
430#300000
431#31000000
432#3200000000
433#330000000000
434#34000000000000
435#3500000000000000
436#36
437#37
438#3800
439#390000
43A#3A000000
43B#3B00000000
43C#3C0000000000
43D#3D000000000000
43E#3E00000000000000
EOF

# cat $expect_log_file_path


spawn_master $lin0


candump $lin0_dev_name,#ffffffff -L >$dev_log_file_path 2>/dev/null &
pids+=($!)

echo INFO: Generating master tx frames | tee -a "$meta_log_path"
cangen $cangen_common_args -I i -L i -D i $lin0_dev_name -n $frame_count &
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
