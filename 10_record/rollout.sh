#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")
LOG_DIR=${PWD}/../log

# run the ddl in the server that will host the postgres database
create_record_table() {
  psql -U postgres -f ${PWD}/ddl_record_table.sql
}

save_gucs() {
  echo "saving GUCs"
  ${PWD}/../tpcds_tools/tpcds_get_gucs.sh > ${LOG_DIR}/10_gucs.out
}

get_parent_device_size_gb() {
  directory=$1
  data_dev=$(findmnt --target ${directory} -no SOURCE)
  parent_dev=$(lsblk -no pkname $data_dev)
  if [ x"$parent_dev" != x"" ]; then
    parent_dev=/dev/$parent_dev
  else
    parent_dev=$data_dev
  fi
  data_disk_bytes=$(lsblk -bdno SIZE $parent_dev)
  # ignore decimals
  dev_disk_gb=$(echo "${data_disk_bytes} / 1024 / 1024 / 1024" | bc)
  echo $dev_disk_gb
}

save_system_config() {
  echo "saving system configuration"
  root_disk_gb=$(get_parent_device_size_gb "/")
  data_disk_gb=$(get_parent_device_size_gb "${MASTER_DATA_DIRECTORY}")
  cat > ${LOG_DIR}/10_system_config.out << EOF
{
"cpu": $(lscpu | grep ^CPU\(s\): | awk '{print $2}'),
"cpu_model": "$(lscpu | grep "^Model name" | cut -d: -f2 | xargs)",
"data_disk_gb": ${data_disk_gb},
"kernel": "$(uname -r)",
"memory_gb": $(free -g|head -2|tail -1|awk '{printf "%s\n", $2}'),
"rhp": "$(grep  HugePages_Total /proc/meminfo | awk '{print $2}')",
"root_disk_gb": ${root_disk_gb},
"thp": "to-do"
}
EOF
}


save_greenplum_info() {
  echo "saving greenplum info"
  cat > ${LOG_DIR}/10_greenplum_info.out<< EOF
{
  "cluster_size": $(psql -tA -c "select count(*) from gp_segment_configuration"),
  "deployment_type": "$(psql -tA -c "select case WHEN count=0 THEN 'mirrorless' ELSE 'mirrored' END from (select count(*) from gp_segment_configuration where preferred_role!='p') as count;")",
  "gucs": "$(awk '{printf "%s\\n", $0}' ${LOG_DIR}/10_gucs.out)",
  "role": "${BENCH_ROLE}"
}
EOF
}

# TODO: maybe in tpcds_variables.sh?
INFRA_NAME="WORKSTATION-CENTOS7"
DATASTORE_TYPE="vSAN"
DESCRIPTION=${INFRA_NAME}

save_infra_info() {
  echo "saving infrastructure info"
  cat > ${LOG_DIR}/10_infra_info.out<< EOF
{
  "infra_name": "${INFRA_NAME}",
  "datastore_type": "${DATASTORE_TYPE}"
}
EOF
}

save_score_v131() {
  source ${LOG_DIR}/09_score.env
  echo "saving score for version 1.3.1"
  cat > ${LOG_DIR}/10_score_v131.out<< EOF
{
  "sq": ${S_Q},
  "q": ${Q_1_3_1},
  "tld": ${TLD_1_3_1},
  "tpt": ${TPT_1_3_1},
  "ttt": ${TTT_1_3_1},
  "score": ${SCORE_1_3_1}
}
EOF
}

save_score_v220() {
  source ${LOG_DIR}/09_score.env
  echo "saving score for version 2.0.0"
  cat > ${LOG_DIR}/10_score_v220.out<< EOF
{
  "sq": ${S_Q},
  "q": ${Q_2_2_0},
  "tld": ${TLD_2_2_0},
  "tpt": ${TPT_2_2_0},
  "ttt": ${TTT_2_2_0},
  "score": ${SCORE_2_2_0}
}
EOF
}

save_single_user() {
  echo "saving single user information"
  cat > ${LOG_DIR}/10_single_user.out<< EOF
{
  "time": "something here"
}
EOF
}

save_tpcds_variables() {
  cp ${PWD}/../tpcds_variables.sh ${LOG_DIR}/10_tpcds_variables.tmp
  sed -i -e 's/\"/\\"/g' ${LOG_DIR}/10_tpcds_variables.tmp
  echo "saving single user information"
  cat > ${LOG_DIR}/10_tpcds_variables.out<< EOF
{
  "variables": "$(awk '{printf "%s\\n", $0}' ${LOG_DIR}/10_tpcds_variables.tmp)"
}
EOF
}

generate_payload() {
  source ${LOG_DIR}/09_score.env
   echo "{
   \"analyze_sec\": ${ANALYZE_TIME},
   \"description\": \"${DESCRIPTION}\",
   \"story_id\": \"some reference here\",
   \"notes\": \"some notes here\",
   \"greenplum_info\": $(cat ${LOG_DIR}/10_greenplum_info.out),
   \"infra_info\": $(cat ${LOG_DIR}/10_infra_info.out),
   \"load_sec\": ${LOAD_TIME},
   \"num_of_streams\": ${S_Q},
   \"scale_factor\": ${SF},
   \"score_v131\": $(cat ${LOG_DIR}/10_score_v131.out),
   \"score_v220\": $(cat ${LOG_DIR}/10_score_v220.out),
   \"single_user\": $(cat ${LOG_DIR}/10_single_user.out),
   \"single_user_sec\": ${QUERIES_TIME},
   \"sum_of_elapsetime_all_con_query_sec\": ${CONCURRENT_QUERY_TIME},
   \"system_config\": $(cat ${LOG_DIR}/10_system_config.out),
   \"throughput_test_elapase_time_sec\": ${THROUGHPUT_ELAPSED_TIME},
   \"tpcds_variables\": $(cat ${LOG_DIR}/10_tpcds_variables.out)
   }"
}

submit_payload_to_api_server() {
  echo "Recording GPDS bench information to remote server"
  echo $(generate_payload) > ${LOG_DIR}/10_gpds_bench.out
  result=$(curl -H "Content-Type: application/json" -X POST "${ADDRESS}:9090/tpcds/gpds_bench" --data "$(cat ${LOG_DIR}/10_gpds_bench.out)")
  status_code=$(echo $result  | jq -r .status_code)
  if [ ${status_code} -eq 200 ]; then
    echo "Successfully recorded the information to the remote server"
  fi
  echo ""
}

#TODO: should be in tpcds_variables
ADDRESS=

_main() {
  step="record"
  init_log ${step}

  echo "Retrieving system information"
  save_gucs
  save_system_config
  save_greenplum_info
  save_infra_info
  save_score_v131
  save_score_v220
  save_single_user
  save_tpcds_variables
  submit_payload_to_api_server
  echo "Retrieving Greenplum cluster setup"

  echo "Finished ${step}"
}

_main
