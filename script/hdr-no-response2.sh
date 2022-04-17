#!/bin/bash

set -e

if [ $# -ne 2 ]; then
	echo "ERROR: $(basename $0) LIN0 LIN1"
	exit 1
fi

lin0=$1
lin1=$2

shift
shift


trap test_error_cleanup EXIT

echo INFO: Setting up $lin0 as master | tee -a "$meta_log_path"
slcand -o $slcand_common_args $lin0 &
pids+=($!)

echo INFO: Setting up $lin1 as slave | tee -a "$meta_log_path"
slcand -o $slcand_common_args $lin1 &
pids+=($!)


exit 0
