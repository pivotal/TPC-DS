#!/bin/bash
set -e

if [ "$(alias | grep -wc grep)" -gt 0 ]; then
  unalias grep
fi
if [ "$(alias | grep -wc ls)" -gt 0 ]; then
  unalias ls
fi

################################################################################
####  Unexported functions  ####################################################
################################################################################
function check_variable() {
  local var_name="${1}"
  shift

  if [ -z "${!var_name}" ]; then
    echo "${var_name} is not defined in ${VARS_FILE}. Exiting."
    exit 1
  fi
}

function check_variables() {
  ### Make sure variables file is available
  echo "############################################################################"
  echo "Sourcing ${VARS_FILE}"
  echo "############################################################################"
  echo ""
  # shellcheck source=tpcds_variables.sh
  if ! source "./${VARS_FILE}" 2> /dev/null; then
    echo "./${VARS_FILE} does not exist. Please ensure that this file exists before running TPC-DS. Exiting."
    exit 1
  fi

  check_variable "ADMIN_USER"
  check_variable "EXPLAIN_ANALYZE"
  check_variable "RANDOM_DISTRIBUTION"
  check_variable "MULTI_USER_COUNT"
  check_variable "GEN_DATA_SCALE"
  check_variable "SINGLE_USER_ITERATIONS"
  check_variable "HEAP_ONLY"
  check_variable "GPFDIST_LOCATION"
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
  check_variable "RUN_SINGLE_USER_REPORTS"
  #07
  check_variable "RUN_MULTI_USER"
  #08
  check_variable "RUN_MULTI_USER_REPORTS"
  #09
  check_variable "RUN_SCORE"
  #10
  check_variable "BENCH_ROLE"
}

function check_admin_user() {
  echo "############################################################################"
  echo "Ensure ${ADMIN_USER} is executing this script."
  echo "############################################################################"
  echo ""
  if [ "$(whoami)" != "${ADMIN_USER}" ]; then
    echo "Script must be executed as ${ADMIN_USER}!"
    exit 1
  fi
}

function print_header() {
  echo "############################################################################"
  echo "ADMIN_USER: ${ADMIN_USER}"
  echo "MULTI_USER_COUNT: ${MULTI_USER_COUNT}"
  echo "############################################################################"
  echo ""
}

# we need to declare this outside, otherwise, the declare will wipe out the
# value within a function
declare startup_file
startup_file="${HOME}/.bashrc"
function source_bashrc() {
  if [ -f "${startup_file}" ]; then
    # don't fail if an error is happening in the admin's profile
    # shellcheck disable=SC1090
    source "${startup_file}" || true
  fi
  count=$(grep -E -c "source .*/greenplum_path.sh|\. .*/greenplum_path.sh" "${startup_file}" || true)
  if [ "${count}" -eq 0 ]; then
    echo "${HOME}/.bashrc does not contain greenplum_path.sh"
    echo "Please update your ${startup_file} for ${ADMIN_USER} and try again."
    exit 1
  elif [ "${count}" -gt 1 ]; then
    echo "${HOME}/.bashrc contains multiple greenplum_path.sh entries"
    echo "Please update your ${startup_file} for ${ADMIN_USER} and try again."
    exit 1
  else
    get_version
  fi
}

################################################################################
####  Exported functions  ######################################################
################################################################################
function get_pwd() {
  # Handle relative vs absolute path
  [ "${1:0:1}" == '/' ] && x="${1}" || x="${PWD}/${1}"
  # Change to dirname of x
  cd "${x%/*}"
  # Combine new pwd with basename of x
  # shellcheck disable=SC2005
  echo "$(dirname "$(pwd -P)/${x##*/}")"
  cd "${OLDPWD}"
}
export -f get_pwd

function get_gpfdist_port() {
  all_ports=$(psql -t -A -c "select min(case when role = 'p' then port else 999999 end), min(case when role = 'm' then port else 999999 end) from gp_segment_configuration where content >= 0")
  primary_base=$(echo "${all_ports}" | awk -F '|' '{print $1}' | head -c1)
  mirror_base=$(echo "${all_ports}" | awk -F '|' '{print $2}' | head -c1)

  for i in $(seq 4 9); do
    if [ "${primary_base}" -ne "${i}" ] && [ "$mirror_base" -ne "${i}" ]; then
      GPFDIST_PORT="${i}000"
      export GPFDIST_PORT
      break
    fi
  done
}
export -f get_gpfdist_port

function get_version() {
  VERSION=$(psql -v ON_ERROR_STOP=1 -t -A -c \
    "SELECT CASE WHEN POSITION ('Greenplum Database 4.3' IN version) > 0 THEN 'gpdb_4_3' \
    WHEN POSITION ('Greenplum Database 5' IN version) > 0 THEN 'gpdb_5' \
    WHEN POSITION ('Greenplum Database 6' IN version) > 0 THEN 'gpdb_6' \
    WHEN POSITION ('Greenplum Database 7' IN version) > 0 THEN 'gpdb_7' \
    ELSE 'postgresql' END FROM version();")

  export VERSION

  if [ "${HEAP_ONLY}" == "true" ]; then
    HEAP_STORAGE="appendonly=false"
    SMALL_STORAGE="${HEAP_STORAGE}"
    MEDIUM_STORAGE="${HEAP_STORAGE}"
    LARGE_STORAGE="${HEAP_STORAGE}"
  else
    quicklz_test=$(psql -v ON_ERROR_STOP=1 -t -A -c "SELECT COUNT(1) FROM pg_compression WHERE compname = 'quicklz'")
    zlib_test=$(psql -v ON_ERROR_STOP=1 -t -A -c "SELECT COUNT(1) FROM pg_compression WHERE compname = 'zlib'")
    zstd_test=$(psql -v ON_ERROR_STOP=1 -t -A -c "SELECT COUNT(1) FROM pg_compression WHERE compname = 'zstd'")

    SMALL_STORAGE="appendonly=true, orientation=column"
    MEDIUM_STORAGE="appendonly=true, orientation=column"

    if [ "${zstd_test}" -eq "1" ]; then
      LARGE_STORAGE="appendonly=true, orientation=column, compresstype=zstd"
    elif [ "${quicklz_test}" -eq "1" ]; then
      LARGE_STORAGE="appendonly=true, orientation=column, compresstype=quicklz"
    elif [ "${zlib_test}" -eq "1" ]; then
      LARGE_STORAGE="appendonly=true, orientation=column, compresstype=zlib, compresslevel=4"
    else
      LARGE_STORAGE="appendonly=true, orientation=column"
    fi
  fi

  export SMALL_STORAGE
  export MEDIUM_STORAGE
  export LARGE_STORAGE
}
export -f get_version

function init_log() {
  logfile="rollout_${1}.log"
  rm -f "${TPC_DS_DIR}/log/${logfile}"
}
export -f init_log

function start_log() {
  T_START="$(date +%s)"
}
export -f start_log

# we need to declare this outside, otherwise, the declare will wipe out the
# value within a function
declare schema_name
declare table_name
function print_log() {
  set -ue
  #duration
  T_END="$(date +%s)"
  T_DURATION="$((T_END - T_START))"
  S_DURATION=${T_DURATION}
  local id="${1}"
  shift
  local schema_name="${1}"
  shift
  local table_name="${1}"
  shift
  local tuples="${1}"
  shift
  set +ue

  #this is done for steps that don't have id values
  if [ "${id}" == "" ]; then
    echo "ERROR: no id found when printing log"
    exit 1
  fi

  # calling function adds schema_name and table_name
  printf "%s|%s.%s|%s|%02d:%02d:%02d|%d|%d\n" "${id}" "${schema_name}" "${table_name}" "${tuples}" "$((S_DURATION / 3600 % 24))" "$((S_DURATION / 60 % 60))" "$((S_DURATION % 60))" "${T_START}" "${T_END}" >> "${TPC_DS_DIR}/log/${logfile}"
}
export -f print_log

function end_step() {
  local logfile=end_${1}.log
  touch "${TPC_DS_DIR}/log/${logfile}"
}
export -f end_step

function log_time() {
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}
export -f log_time

function create_hosts_file() {
  # not used for this function
  # get_version

  SQL_QUERY="SELECT DISTINCT hostname FROM gp_segment_configuration WHERE role = '${GPFDIST_LOCATION}' AND content >= 0"
  psql -v ON_ERROR_STOP=1 -t -A -c "${SQL_QUERY}" -o "${TPC_DS_DIR}"/segment_hosts.txt
}
export -f create_hosts_file
