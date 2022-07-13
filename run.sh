#/bin/bash

logfilename=$(date +%Y%m%d)_$(date +%H%M%S)
nohup sh tpcds.sh > tpcds_$logfilename.log 2>&1 &
