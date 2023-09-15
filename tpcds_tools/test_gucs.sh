#!/usr/bin/env bash

source gucs.sh

export BASH_MAJOR_VERSION=3
[ "$(_check_minimal_bash_version)" == "require bash 4.0 to run" ] && echo pass || echo expect to fail for BASH major version 3

export BASH_MAJOR_VERSION=4
$(_check_minimal_bash_version) && echo pass || echo expect to pass for BASH major version 4

_execute_psql() {
  printf '6'
}
[ $(_get_database_version) == "6" ] && echo pass || echo expect to get database version 6

_execute_psql() {
  printf 'mirrorless'
}
[ $(_get_deployment_type) == 'mirrorless' ] && echo pass || echo expect to get deployment type as mirrorless

_get_gpconfig() {
  printf "$1\n"
}
_get_database_version() {
  printf '6'
}
_get_deployment_type() {
  printf 'mirrored'
}
[[ "$(get_gucs)" == *"gp_resource_group_cpu_priority
gp_resource_group_memory_limit
gp_resgroup_memory_policy"* ]] && echo pass || echo "expect GPDB6 GUC gp_resource_group_memory_limit"
[[ "$(get_gucs)" == *"skip GUC (GP6, mirrored): gp_dispatch_keepalives_idle
skip GUC (GP6, mirrored): gp_dispatch_keepalives_interval
skip GUC (GP6, mirrored): gp_dispatch_keepalives_count"* ]] && echo pass || echo "expect unhandled mirrorless GUCs"

_get_gpconfig() {
  printf "$1\n"
}
_get_database_version() {
  printf '7'
}
_get_deployment_type() {
  printf 'mirrorless'
}
[[ "$(get_gucs)" == *"gp_resource_group_cpu_priority
skip GUC (GP7, mirrorless): gp_resource_group_memory_limit
gp_resgroup_memory_policy"* ]] && echo pass || echo "expect GPDB7 GUC, without the gp_resource_group_memory_limit"
[[ "$(get_gucs)" == *"max_statement_mem
statement_mem"* ]] && echo pass || echo "expect max_statement_mem before statement_mem in GP7"

_set_gpconfig() {
  printf "$1 $2\n"
}
_get_database_version() {
  printf '7'
}
_get_deployment_type() {
  printf 'mirrorless'
}
[[ "$(set_gucs)" == *"runaway_detector_activation_percent 100
gp_dispatch_keepalives_idle 20"* ]] && echo pass || echo "expect GPDB7 set GUC values"

_reset_gpconfig() {
  printf "$1\n"
}
_get_database_version() {
  printf '6'
}
_get_deployment_type() {
  printf 'mirrored'
}
[[ "$(reset_gucs)" == *"gp_resource_group_memory_limit"* ]] && echo pass || echo "expect GPDB6 reset mirrored GUC values"
[[ "$(reset_gucs)" == *"runaway_detector_activation_percent
skip GUC (GP6, mirrored): gp_dispatch_keepalives_idle"* ]] && echo pass || echo "expect GPDB6 skip reset mirrorless GUC values"

_execute_psql() {
  printf "$1\n"
}
[[ "$(get_resource_group)" == *"SELECT * FROM gp_toolkit.gp_resgroup_config order by groupid"* ]] && echo pass || echo "expect to query the gp_toolkit.gp_resgroup_config and order by groupid"

_execute_psql() {
  printf "$1\n"
}
_get_database_version() {
  printf '7'
}
[[ "$(set_resource_group)" == *"CPU_MAX_PERCENT 100"* ]] && echo pass || echo "expect GP7 with CPU_MAX_PERCENT in resource group"

_execute_psql() {
  printf "$1\n"
}
_get_database_version() {
  printf '6'
}
[[ "$(set_resource_group)" == *"admin_group set MEMORY_SHARED_QUOTA 90"* ]] && echo pass || echo "expect GP6 with CPU_RATE_LIMIT in resource group"

_execute_psql() {
  printf "$1\n"
}
_get_database_version() {
  printf '6'
}
[[ "$(reset_resource_groups)" == *"admin_group set MEMORY_SHARED_QUOTA 80"* ]]