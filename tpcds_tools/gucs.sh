#!/usr/bin/env bash
BASH_MAJOR_VERSION=BASH_VERSINFO[0]

# GUC settings are order sensitive
# this is the global order the GUCs will apply
# on GP7, the max_statement_mem has before statement_mem
# otherwise, the gpdb won't be able to start
declare -a gucs_order

gucs_order=(\
gp_interconnect_queue_depth \
gp_interconnect_snd_queue_depth \
\
gp_resource_manager \
\
gp_resource_group_cpu_limit \
gp_resource_group_cpu_priority \
gp_resource_group_memory_limit \
\
gp_resgroup_memory_policy \
gp_workfile_compression \
\
max_statement_mem \
statement_mem \
\
runaway_detector_activation_percent \
\
gp_dispatch_keepalives_idle \
gp_dispatch_keepalives_interval \
gp_dispatch_keepalives_count \
)

declare -A gucs_common gucs_mirrorless gucs_gp7 gucs_gp6

gucs_common=(\
[gp_interconnect_queue_depth]="16" \
[gp_interconnect_snd_queue_depth]="16" \
\
[gp_resource_manager]="group" \
\
[gp_resource_group_cpu_limit]="0.95" \
[gp_resource_group_cpu_priority]="1" \
\
[gp_resgroup_memory_policy]="auto" \
[gp_workfile_compression]="off" \
\
[max_statement_mem]="20GB" \
[statement_mem]="10GB" \
\
[runaway_detector_activation_percent]="100" \
)

gucs_mirrorless=(\
[gp_dispatch_keepalives_idle]="20" \
[gp_dispatch_keepalives_interval]="20" \
[gp_dispatch_keepalives_count]="44" \
)

gucs_gp7=()
gucs_gp6=(\
[gp_resource_group_memory_limit]="0.9" \
)

# configure the GPDB ready for TPC_DS testing
set_gucs() {
  _gucs "set"
}

# get current related configuration for the TPC_DS testing
get_gucs() {
  _gucs "get"
}

# restore the GUCS back to the default settings
reset_gucs() {
  _gucs "reset"
}

set_resource_groups() {
  _check_minimal_bash_version

  _set_resource_groups_common

  local version=$(_get_database_version)
  if [ "${version}" == "7" ]; then
    _set_resource_groups_gp7
  elif [ "${version}" == "6" ]; then
    _set_resource_groups_gp6
  fi
}

get_resource_groups() {
  _check_minimal_bash_version

  _get_resource_groups
}

reset_resource_groups() {
  _check_minimal_bash_version

  _reset_resource_groups_common

  local version=$(_get_database_version)
  if [ "${version}" == "7" ]; then
    _reset_resource_groups_gp7
  elif [ "${version}" == "6" ]; then
    _reset_resource_groups_gp6
  fi
}

##################
# helper functions
##################
_gucs() {
  local action=$1

  if [ "${action}" != "set" ] && [ "${action}" != "reset" ] && [ "${action}" != "get" ]; then
    printf "unknown action: ${action}\n"
    return 1
  fi

  _check_minimal_bash_version

  local version=$(_get_database_version)
  local deployment_type=$(_get_deployment_type)

  for guc in "${gucs_order[@]}"; do
    if [ "${gucs_common[${guc}]}" != "" ]; then
      _gpconfig "${action}" "${guc}" "${gucs_common[${guc}]}"
    elif [ "${gucs_mirrorless[${guc}]}" != "" ] && [ "${deployment_type}" == "mirrorless" ]; then
      _gpconfig "${action}" "${guc}" "${gucs_mirrorless[${guc}]}"
    elif [ "${gucs_gp7[${guc}]}" != "" ] && [ "${version}" == "7" ]; then
      _gpconfig "${action}" "${guc}" "${gucs_gp7[${guc}]}"
    elif [ "${gucs_gp6[${guc}]}" != "" ] && [ "${version}" == "6" ]; then
      _gpconfig "${action}" "${guc}" "${gucs_gp6[${guc}]}"
    else
      printf "skip GUC (GP${version}, ${deployment_type}): ${guc}\n"
    fi
  done

  return 0
}

_check_minimal_bash_version() {
  if ((BASH_MAJOR_VERSION < 4))
  then
    echo "require bash 4.0 to run"
    exit 1
  fi
}

_get_deployment_type() {
  local deployment_type=$(_execute_psql \
  "SELECT CASE WHEN count(*) = 0 THEN 'mirroless' \
  ELSE 'mirrored' END \
  FROM gp_segment_configuration \
  WHERE role='m';")

  printf "${deployment_type}"
}

_get_database_version() {
  local version=$(_execute_psql \
  "SELECT CASE WHEN POSITION ('Greenplum Database 4.3' IN version) > 0 THEN '4' \
  WHEN POSITION ('Greenplum Database 5' IN version) > 0 THEN '5' \
  WHEN POSITION ('Greenplum Database 6' IN version) > 0 THEN '6' \
  WHEN POSITION ('Greenplum Database 7' IN version) > 0 THEN '7' \
  ELSE 'unknown' END FROM version();")

  printf "${version}"
}

_set_resource_groups_common() {
  _set_resource_group "default_group" "CONCURRENCY" "5"
  _set_resource_group "admin_group" "CONCURRENCY" "5"
}

_set_resource_groups_gp7() {
  _set_resource_group "default_group" "CPU_MAX_PERCENT" "100"
  _set_resource_group "default_group" "MEMORY_LIMIT" "25000"
  _set_resource_group "admin_group" "CPU_MAX_PERCENT" "100"
  _set_resource_group "admin_group" "MEMORY_LIMIT" "25000"
  _set_resource_group "system_group" "CPU_MAX_PERCENT" "100"
}

_set_resource_groups_gp6() {
  _set_resource_group "default_group" "CPU_RATE_LIMIT" "90"
  _set_resource_group "default_group" "MEMORY_SHARED_QUOTA" "90"
  _set_resource_group "admin_group" "CPU_RATE_LIMIT" "10"
  _set_resource_group "admin_group" "MEMORY_LIMIT" "10"
  _set_resource_group "admin_group" "MEMORY_SHARED_QUOTA" "90"
  _set_resource_group "admin_group" "MEMORY_SPILL_RATIO" "90"
}

_reset_resource_groups_common() {
  #
  _set_resource_group "default_group" "CONCURRENCY" "20"
  _set_resource_group "admin_group" "CONCURRENCY" "10"
}

_reset_resource_groups_gp6() {
  #
  _set_resource_group "default_group" "CPU_RATE_LIMIT" "30"
  _set_resource_group "default_group" "MEMORY_SHARED_QUOTA" "80"
  _set_resource_group "admin_group" "CPU_RATE_LIMIT" "10"
  _set_resource_group "admin_group" "MEMORY_LIMIT" "10"
  _set_resource_group "admin_group" "MEMORY_SHARED_QUOTA" "80"
  _set_resource_group "admin_group" "MEMORY_SPILL_RATIO" "0"
}

_reset_resource_groups_gp7() {
  #
  _set_resource_group "default_group" "CPU_MAX_PERCENT" "20"
  _set_resource_group "default_group" "MEMORY_LIMIT" "-1"
  _set_resource_group "admin_group" "CPU_MAX_PERCENT" "10"
  _set_resource_group "admin_group" "MEMORY_LIMIT" "-1"
  _set_resource_group "system_group" "CPU_MAX_PERCENT" "10"
}

_get_resource_groups() {
  _execute_psql "SELECT * FROM gp_toolkit.gp_resgroup_config order by groupid"
}

_gpconfig() {
  local action="$1"
  local guc="$2"
  local value="$3"
  if [ "${action}" == "set" ]; then
    _set_gpconfig "${guc}" "${value}"
  elif [ "${action}" == "get" ]; then
    _get_gpconfig "${guc}"
  elif [ "${action}" == "reset" ]; then
    _reset_gpconfig "${guc}"
  else
    printf "unknown action: ${action} for GUC: ${action} (with optional value: ${value})\n"
  fi
}

_get_gpconfig() {
  local guc="$1"
  gpconfig -s "${guc}"
}

_set_gpconfig() {
  local guc="$1"
  local value="$2"
  gpconfig -c "${guc}" -v "${value}"
}

_reset_gpconfig() {
  local guc="$1"
  gpconfig -r "${guc}"
}

_execute_psql() {
  local statement="$1"
  psql -v ON_ERROR_STOP=1 -t -A -c "${statement}" postgres
}

_set_resource_group() {
  local group="$1"
  local key="$2"
  local value="$3"
  _execute_psql "ALTER RESOURCE GROUP ${group} SET ${key} ${value}"
}