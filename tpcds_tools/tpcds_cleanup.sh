#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <no_of_segments>"
  exit 1
fi
echo "Cleaning generated sql files: 05_sql/*.sql"
rm -f 05_sql/*.sql
echo "Cleaning binaries: 00_compile_tpcds/tools"
cd 00_compile_tpcds/tools
make clean
cd -
echo "Cleaning multi-user sql scripts(default 5CU): 07_multi_user/[1-5]"
rm -rf 07_multi_user/[1-5]
echo "Cleaning all tpcds remnents from segment nodes: binary, logs, data, etc."
gpssh $(seq -f "-h sdw%g" 1 ${1}) -e 'rm -f dsdgen generate_data.*.log generate_data.sh gpfdist.*.log hosts-all hosts-segments start_gpfdist.sh stop_gpfdist.sh tpcds.idx; find /gpdata -type d -name dsbenchmark -exec rm -rf {} \;'
