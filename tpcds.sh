#!/bin/bash
set -e

VARS_FILE="tpcds_variables.sh"
##################################################################################################################################################
# Functions
##################################################################################################################################################
check_variable() {
  local var_name="$1"; shift

  if [ ! -n "${!var_name}" ]; then
    echo "${var_name} is not defined in ${VARS_FILE}. Exiting."
    exit 1
  fi
}

check_variables() {
  ### Make sure variables file is available
  echo "############################################################################"
  echo "Sourcing $VARS_FILE"
  echo "############################################################################"
  echo ""
  source $VARS_FILE 2> /dev/null
  if [ $? -ne 0 ]; then
    echo "${VARS_FILE} does not exist. Please ensure that this file exists before running TPC-DS. Exiting."
    exit 1
  fi

  check_variable "ADMIN_USER"
  check_variable "EXPLAIN_ANALYZE"
  check_variable "RANDOM_DISTRIBUTION"
  check_variable "MULTI_USER_COUNT"
  check_variable "GEN_DATA_SCALE"
  check_variable "SINGLE_USER_ITERATIONS"
  #00
  check_variable "RUN_COMPILE_TPCDS"
  #01
  check_variable "RUN_GEN_DATA"
  #02
  check_variable "RUN_INIT"
  #03
  check_variable "RUN_DDL"
  #04
  check_variable "RUN_LOAD"
  #05
  check_variable "RUN_SQL"
  #06
  check_variable "RUN_SINGLE_USER_REPORT"
  #07
  check_variable "RUN_MULTI_USER"
  #08
  check_variable "RUN_MULTI_USER_REPORT"
  #09
  check_variable "RUN_SCORE"
}

check_user() {
  echo "############################################################################"
  echo "Ensure gpadmin is executing this script."
  echo "############################################################################"
  echo ""
  if [ "$(whoami)" != "gpadmin" ]; then
    echo "Script must be executed as gpadmin!"
    exit 1
  fi
}

echo_variables() {
  echo "############################################################################"
  echo "ADMIN_USER: $ADMIN_USER"
  echo "MULTI_USER_COUNT: $MULTI_USER_COUNT"
  echo "############################################################################"
  echo ""
}

##################################################################################################################################################
# Body
##################################################################################################################################################

check_user
check_variables
echo_variables

# run the benchmark
./rollout.sh $GEN_DATA_SCALE $EXPLAIN_ANALYZE $RANDOM_DISTRIBUTION $MULTI_USER_COUNT $RUN_COMPILE_TPCDS $RUN_GEN_DATA $RUN_INIT $RUN_DDL $RUN_LOAD $RUN_SQL $RUN_SINGLE_USER_REPORT $RUN_MULTI_USER $RUN_MULTI_USER_REPORT $RUN_SCORE $SINGLE_USER_ITERATIONS
