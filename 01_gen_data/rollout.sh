#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

if [ "${GEN_DATA_SCALE}" == "" ]; then
  echo "You must provide the scale as a parameter in terms of Gigabytes."
  echo "Example: ./rollout.sh 100"
  echo "This will create 100 GB of data for this test."
  exit 1
fi

function get_count_generate_data() {
  count="0"
  while read -r i; do
    next_count=$(ssh -o ConnectTimeout=0 -n -f ${i} "bash -c 'ps -ef | grep generate_data.sh | grep -v grep | wc -l'" 2>&1 || true)
    check="^[0-9]+$"
    if ! [[ ${next_count} =~ ${check} ]] ; then
      next_count="1"
    fi
    count=$((count + next_count))
  done < ${TPC_DS_DIR}/segment_hosts.txt
}

function kill_orphaned_data_gen() {
  echo "kill any orphaned dsdgen processes on segment hosts"
  # always return true even if no processes were killed
  for i in $(cat ${TPC_DS_DIR}/segment_hosts.txt); do
    ssh ${i} "pkill dsdgen" || true
  done
}

function copy_generate_data() {
  echo "copy generate_data.sh to segment hosts"
  for i in $(cat ${TPC_DS_DIR}/segment_hosts.txt); do
    scp ${PWD}/generate_data.sh ${i}:
  done
}

function gen_data() {
  get_version
  PARALLEL=$(gpstate | grep "Total primary segments" | awk -F '=' '{print $2}')
  if [ "${PARALLEL}" == "" ]; then
    echo "ERROR: Unable to determine how many primary segments are in the cluster using gpstate."
    exit 1
  fi
  echo "parallel: $PARALLEL"
  if [ "${VERSION}" == "gpdb_6" ]; then
    SQL_QUERY="select row_number() over(), g.hostname, g.datadir from gp_segment_configuration g where g.content >= 0 and g.role = '${GPFDIST_LOCATION}' order by 1, 2, 3"
  else
    SQL_QUERY="select row_number() over(), g.hostname, p.fselocation as path from gp_segment_configuration g join pg_filespace_entry p on g.dbid = p.fsedbid join pg_tablespace t on t.spcfsoid = p.fsefsoid where g.content >= 0 and g.role = '${GPFDIST_LOCATION}' and t.spcname = 'pg_default' order by 1, 2, 3"
  fi
  for i in $(psql -v ON_ERROR_STOP=1 -q -A -t -c "${SQL_QUERY}"); do
    CHILD=$(echo ${i} | awk -F '|' '{print $1}')
    EXT_HOST=$(echo ${i} | awk -F '|' '{print $2}')
    GEN_DATA_PATH=$(echo ${i} | awk -F '|' '{print $3}')
    GEN_DATA_PATH="${GEN_DATA_PATH}/dsbenchmark"
    echo "ssh -n -f ${EXT_HOST} \"bash -c \'cd ~/; ./generate_data.sh ${GEN_DATA_SCALE} ${CHILD} ${PARALLEL} ${GEN_DATA_PATH} > generate_data.${CHILD}.log 2>&1 < generate_data.${CHILD}.log &\'\""

    ssh -n -f ${EXT_HOST} "bash -c 'cd ~/; ./generate_data.sh ${GEN_DATA_SCALE} ${CHILD} ${PARALLEL} ${GEN_DATA_PATH} > generate_data.${CHILD}.log 2>&1 < generate_data.${CHILD}.log &'"
  done
}

step="gen_data"
init_log ${step}
start_log
schema_name="tpcds"
table_name="gen_data"

if [ "${GEN_NEW_DATA}" == "true" ]; then
  kill_orphaned_data_gen
  copy_generate_data
  gen_data

  echo ""
  get_count_generate_data
  echo "Now generating data.  This may take a while."
  minutes=0
  echo -ne "Generating data duration: "
  tput sc
  while [ "$count" -gt "0" ]; do
    tput rc
    echo -ne "${minutes} minute(s)"
    sleep 60
    minutes=$(( minutes + 1 ))
    get_count_generate_data
  done

  echo ""
  echo "Done generating data"
  echo ""
fi

echo "Generate queries based on scale"
cd ${PWD}
${PWD}/generate_queries.sh

print_log

echo "Finished ${step}"
