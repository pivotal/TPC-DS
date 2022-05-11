#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

step="compile_tpcds"
init_log ${step}
start_log
schema_name="tpcds"
table_name="compile"

function make_tpc()
{
  #compile the tools
  cd ${PWD}/tools
  rm -f ./*.o
  make
  cd ..
}

function copy_tpc()
{
  cp ${PWD}/tools/dsqgen ../*_gen_data/
  cp ${PWD}/tools/dsqgen ../*_multi_user/
  cp ${PWD}/tools/tpcds.idx ../*_gen_data/
  cp ${PWD}/tools/tpcds.idx ../*_multi_user/

  #copy the compiled dsdgen program to the segment nodes
  echo "copy tpcds binaries to segment hosts"
  for i in $(cat ${TPC_DS_DIR}/segment_hosts.txt); do
    scp tools/dsdgen tools/tpcds.idx ${i}:
  done
}

function copy_queries()
{
  rm -rf ${TPC_DS_DIR}/*_gen_data/query_templates
  rm -rf ${TPC_DS_DIR}/*_multi_user/query_templates
  cp -R query_templates ${TPC_DS_DIR}/*_gen_data/
  cp -R query_templates ${TPC_DS_DIR}/*_multi_user/
}

make_tpc
create_hosts_file
copy_tpc
copy_queries
print_log

echo "Finished ${step}"
