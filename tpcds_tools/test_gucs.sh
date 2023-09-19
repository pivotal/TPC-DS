#!/usr/bin/env bash
SCRIPTDIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# shellcheck source=gucs.sh
source "${SCRIPTDIR}/gucs.sh"

export BASH_MAJOR_VERSION=3
[ "$(_check_minimal_bash_version)" == "require bash 4.0 to run" ] && echo pass || echo expect to fail for BASH major version 3

export BASH_MAJOR_VERSION=4
_check_minimal_bash_version && echo pass || echo expect to pass for BASH major version 4

_execute_psql() {
  printf '6'
}
[ "$(_get_database_version)" == "6" ] && echo pass || echo expect to get database version 6

_execute_psql() {
  echo "$1"
}
[[ "$(_get_deployment_type)" == *"SELECT CASE WHEN count(*) = 0 THEN 'mirrorless'"* ]] && echo pass || echo expect to get deployment type as mirrorless

_get_gpconfig() {
  echo "$1"
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

[[ "$(_gpconfig clear guc value)" == *"unknown action: clear for GUC: guc (with optional value: value)"* ]] && echo pass || echo "expect unknown action clear"

_get_gpconfig() {
  echo "$1"
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
[[ "$(get_gucs)" == *"gp_dispatch_keepalives_idle
gp_dispatch_keepalives_interval
gp_dispatch_keepalives_count"* ]] && echo pass || echo "expect output mirrorless GUCs"

_set_gpconfig() {
  echo "$1 $2"
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
  echo "$1"
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
  echo "$1"
}
[[ "$(get_resource_groups)" == *"SELECT * FROM gp_toolkit.gp_resgroup_config order by groupid"* ]] && echo pass || echo "expect to query the gp_toolkit.gp_resgroup_config and order by groupid"

_set_resource_group() {
  echo "$1 SET $2 $3"
}
_get_database_version() {
  printf '7'
}
[[ "$(set_resource_groups)" == *"default_group SET CONCURRENCY 5"* ]] && echo pass || echo "expect set GP7 with CONCURRENCY in default_group resource group"
[[ "$(set_resource_groups)" == *"default_group SET CPU_MAX_PERCENT 100"* ]] && echo pass || echo "expect set GP7 with CPU_MAX_PERCENT in default_group resource group"
[[ "$(set_resource_groups)" == *"default_group SET MEMORY_LIMIT 25000"* ]] && echo pass || echo "expect set GP7 with MEMORY_LIMIT in default_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET CONCURRENCY 5"* ]] && echo pass || echo "expect set GP7 with CONCURRENCY in admin_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET CPU_MAX_PERCENT 100"* ]] && echo pass || echo "expect set GP7 with CPU_MAX_PERCENT in admin_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET MEMORY_LIMIT 25000"* ]] && echo pass || echo "expect set GP7 with MEMORY_LIMIT in admin_group resource group"
[[ "$(set_resource_groups)" == *"system_group SET CPU_MAX_PERCENT 100"* ]] && echo pass || echo "expect set GP7 with CPU_MAX_PERCENT in system_group resource group"

_set_resource_group() {
  echo "$1 SET $2 $3"
}
_get_database_version() {
  printf '6'
}
[[ "$(set_resource_groups)" == *"default_group SET CONCURRENCY 5"* ]] && echo pass || echo "expect set GP6 with CONCURRENCY in default_group resource group"
[[ "$(set_resource_groups)" == *"default_group SET CPU_RATE_LIMIT 90"* ]] && echo pass || echo "expect set GP6 with CPU_RATE_LIMIT in default_group resource group"
[[ "$(set_resource_groups)" == *"default_group SET MEMORY_SHARED_QUOTA 90"* ]] && echo pass || echo "expect set GP6 with MEMORY_SHARED_QUOTA in default_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET CONCURRENCY 5"* ]] && echo pass || echo "expect set GP6 with CONCURRENCY in admin_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET CPU_RATE_LIMIT 10"* ]] && echo pass || echo "expect set GP6 with CPU_RATE_LIMIT in admin_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET MEMORY_LIMIT 10"* ]] && echo pass || echo "expect set GP6 with MEMORY_LIMIT in admin_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET MEMORY_SHARED_QUOTA 90"* ]] && echo pass || echo "expect set GP6 with MEMORY_SHARED_QUOTA in admin_group resource group"
[[ "$(set_resource_groups)" == *"admin_group SET MEMORY_SPILL_RATIO 90"* ]] && echo pass || echo "expect set GP6 with MEMORY_SPILL_RATIO in admin_group resource group"

_set_resource_group() {
  echo "$1 SET $2 $3"
}
_get_database_version() {
  printf '6'
}
# based on pg_resgroupcapability.h
[[ "$(reset_resource_groups)" == *"default_group SET CONCURRENCY 20"* ]] && echo pass || echo "expect reset GP6 with CONCURRENCY in default_group resource group"
[[ "$(reset_resource_groups)" == *"default_group SET CPU_RATE_LIMIT 30"* ]] && echo pass || echo "expect reset GP6 with CPU_RATE_LIMIT in default_group resource group"
[[ "$(reset_resource_groups)" == *"default_group SET MEMORY_SHARED_QUOTA 80"* ]] && echo pass || echo "expect reset GP6 with MEMORY_SHARED_QUOTA in default_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET CONCURRENCY 10"* ]] && echo pass || echo "expect reset GP6 with CONCURRENCY in admin_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET CPU_RATE_LIMIT 10"* ]] && echo pass || echo "expect reset GP6 with CPU_RATE_LIMIT in admin_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET MEMORY_LIMIT 10"* ]] && echo pass || echo "expect reset GP6 with MEMORY_LIMIT in admin_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET MEMORY_SHARED_QUOTA 80"* ]] && echo pass || echo "expect reset GP6 with MEMORY_SHARED_QUOTA in admin_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET MEMORY_SPILL_RATIO 0"* ]] && echo pass || echo "expect reset GP6 with MEMORY_SPILL_RATIO in admin_group resource group"

_set_resource_group() {
  echo "$1 SET $2 $3"
}
_get_database_version() {
  printf '7'
}
# based on pg_resgroupcapability.dat
[[ "$(reset_resource_groups)" == *"default_group SET CONCURRENCY 20"* ]] && echo pass || echo "expect reset GP7 with CONCURRENCY in default_group resource group"
[[ "$(reset_resource_groups)" == *"default_group SET CPU_MAX_PERCENT 20"* ]] && echo pass || echo "expect reset GP7 with CPU_MAX_PERCENT in default_group resource group"
[[ "$(reset_resource_groups)" == *"default_group SET MEMORY_LIMIT -1"* ]] && echo pass || echo "expect reset GP7 with MEMORY_LIMIT in default_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET CONCURRENCY 10"* ]] && echo pass || echo "expect reset GP7 with CONCURRENCY in admin_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET CPU_MAX_PERCENT 10"* ]] && echo pass || echo "expect reset GP7 with CPU_MAX_PERCENT in admin_group resource group"
[[ "$(reset_resource_groups)" == *"admin_group SET MEMORY_LIMIT -1"* ]] && echo pass || echo "expect reset GP7 with MEMORY_LIMIT in admin_group resource group"
[[ "$(reset_resource_groups)" == *"system_group SET CPU_MAX_PERCENT 10"* ]] && echo pass || echo "expect reset GP7 with CPU_MAX_PERCENT in system_group resource group"
