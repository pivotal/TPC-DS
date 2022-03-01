#!/bin/bash

set -e
PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/functions.sh
source_bashrc

GEN_DATA_SCALE="${1}"
EXPLAIN_ANALYZE="${2}"
RANDOM_DISTRIBUTION="${3}"
MULTI_USER_COUNT="${4}"
RUN_COMPILE_TPCDS="${5}"
RUN_GEN_DATA="${6}"
RUN_INIT="${7}"
RUN_DDL="${8}"
RUN_LOAD="${9}"
RUN_SQL="${10}"
RUN_SINGLE_USER_REPORTS="${11}"
RUN_MULTI_USER="${12}"
RUN_MULTI_USER_REPORTS="${13}"
RUN_SCORE="${14}"
SINGLE_USER_ITERATIONS="${15}"
BENCH_ROLE="${16}"

if [[ "${GEN_DATA_SCALE}" == "" \
  || "${EXPLAIN_ANALYZE}" == "" \
  || "${RANDOM_DISTRIBUTION}" == "" \
  || "${MULTI_USER_COUNT}" == "" \
  || "${RUN_COMPILE_TPCDS}" == "" \
  || "${RUN_GEN_DATA}" == "" \
  || "${RUN_INIT}" == "" \
  || "${RUN_DDL}" == "" \
  || "${RUN_LOAD}" == "" \
  || "${RUN_SQL}" == "" \
  || "${RUN_SINGLE_USER_REPORTS}" == "" \
  || "${RUN_MULTI_USER}" == "" \
  || "${RUN_MULTI_USER_REPORTS}" == "" \
  || "${RUN_SCORE}" == "" \
  || "${SINGLE_USER_ITERATIONS}" == "" \
  || "${BENCH_ROLE}" == "" ]]; then
  echo "Please run this script from tpcds.sh so the correct parameters are passed to it."
  exit 1
fi

QUIET=$5

create_directories()
{
  if [ ! -d $LOCAL_PWD/log ]; then
    echo "Creating log directory"
    mkdir $LOCAL_PWD/log
  fi
}

create_directories
echo "############################################################################"
echo "TPC-DS Script for Pivotal Greenplum Database."
echo "############################################################################"
echo ""
echo "############################################################################"
echo "GEN_DATA_SCALE: ${GEN_DATA_SCALE}"
echo "EXPLAIN_ANALYZE: ${EXPLAIN_ANALYZE}"
echo "RANDOM_DISTRIBUTION: ${RANDOM_DISTRIBUTION}"
echo "MULTI_USER_COUNT: ${MULTI_USER_COUNT}"
echo "RUN_COMPILE_TPCDS: ${RUN_COMPILE_TPCDS}"
echo "RUN_GEN_DATA: ${RUN_GEN_DATA}"
echo "RUN_INIT: ${RUN_INIT}"
echo "RUN_DDL: ${RUN_DDL}"
echo "RUN_LOAD: ${RUN_LOAD}"
echo "RUN_SQL: ${RUN_SQL}"
echo "SINGLE_USER_ITERATIONS: ${SINGLE_USER_ITERATIONS}"
echo "RUN_SINGLE_USER_REPORTS: ${RUN_SINGLE_USER_REPORTS}"
echo "RUN_MULTI_USER: ${RUN_MULTI_USER}"
echo "RUN_MULTI_USER_REPORTS: ${RUN_MULTI_USER_REPORTS}"
echo "BENCH_ROLE: ${BENCH_ROLE}"
echo "############################################################################"
echo ""

# We assume that the flag variable names are consistent with the corresponding directory names.
# For example, `00_compile_tpcds directory` name will be used to get `true` or `false` value from `RUN_COMPILE_TPCDS` in `tpcds_variables.sh`.
for i in $(ls -d $PWD/0*); do
  step_name=${i#*_} # split by the first underscore and extract the step name.
  flag_name="RUN_""$(echo $step_name|tr [a-z] [A-Z])" # convert to upper case and concatenate "RUN_" in the front to get the flag name.
  run_flag=${!flag_name} # use indirect reference to convert flag name string to its value as "true" or "false".

  if [ "$run_flag" == "true" ]; then
    echo "Run $i/rollout.sh ${GEN_DATA_SCALE} ${EXPLAIN_ANALYZE} ${RANDOM_DISTRIBUTION} ${MULTI_USER_COUNT} ${SINGLE_USER_ITERATIONS} ${BENCH_ROLE}"
    $i/rollout.sh ${GEN_DATA_SCALE} ${EXPLAIN_ANALYZE} ${RANDOM_DISTRIBUTION} ${MULTI_USER_COUNT} ${SINGLE_USER_ITERATIONS} ${BENCH_ROLE}
  elif [ "$run_flag" == "false" ]; then
    echo "Skip $i/rollout.sh"
  else
    echo "Aborting script because ${flag_name} is not properly specified: must be either \"true\" or \"false\"."
    exit 1
  fi
done
