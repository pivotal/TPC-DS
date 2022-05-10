#!/bin/bash

set -e
PWD=$(get_pwd ${BASH_SOURCE[0]})

################################################################################
####  Local functions  #########################################################
################################################################################
function create_directories()
{
  if [ ! -d ${TPC_DS_DIR}/log ]; then
    echo "Creating log directory"
    mkdir ${TPC_DS_DIR}/log
  fi
}

################################################################################
####  Body  ####################################################################
################################################################################
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
echo "GEN_NEW_DATA: ${GEN_NEW_DATA}"
echo "RUN_INIT: ${RUN_INIT}"
echo "RUN_DDL: ${RUN_DDL}"
echo "DROP_EXISTING_TABLES: ${DROP_EXISTING_TABLES}"
echo "RUN_LOAD: ${RUN_LOAD}"
echo "RUN_SQL: ${RUN_SQL}"
echo "SINGLE_USER_ITERATIONS: ${SINGLE_USER_ITERATIONS}"
echo "RUN_SINGLE_USER_REPORTS: ${RUN_SINGLE_USER_REPORTS}"
echo "RUN_MULTI_USER: ${RUN_MULTI_USER}"
echo "RUN_MULTI_USER_REPORTS: ${RUN_MULTI_USER_REPORTS}"
echo "BENCH_ROLE: ${BENCH_ROLE}"
echo "GPFDIST_LOCATION: ${GPFDIST_LOCATION}"
echo "############################################################################"
echo ""

# We assume that the flag variable names are consistent with the corresponding directory names.
# For example, `00_compile_tpcds directory` name will be used to get `true` or `false` value from `RUN_COMPILE_TPCDS` in `tpcds_variables.sh`.
for i in $(ls -d ${PWD}/0*); do
  # split by the first underscore and extract the step name.
  step_name=${i#*_}
  # convert to upper case and concatenate "RUN_" in the front to get the flag name.
  flag_name="RUN_$(echo ${step_name} | tr [:lower:] [:upper:])"
  # use indirect reference to convert flag name string to its value as "true" or "false".
  run_flag=${!flag_name}

  if [ "${run_flag}" == "true" ]; then
    echo "Run ${i}/rollout.sh"
    ${i}/rollout.sh
  elif [ "${run_flag}" == "false" ]; then
    echo "Skip ${i}/rollout.sh"
  else
    echo "Aborting script because ${flag_name} is not properly specified: must be either \"true\" or \"false\"."
    exit 1
  fi
done
