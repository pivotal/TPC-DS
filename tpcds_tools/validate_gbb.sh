#!/usr/bin/env bash

# This script needs to be run as root!
if [ "${EUID}" -ne 0 ]; then
  echo "ERROR: ${0} must be run as root"
  exit
fi

get_ram() {
  case $1 in
  b | k | m | g)
    printf "%d" "$(free -${1} | grep "^Mem:" | awk '{ print $2 }')"
    ;;
  *)
    printf "-1"
    ;;
  esac
}

get_swap() {
  case ${1} in
  b | k | m | g)
    printf "%d" "$(free -${1} | grep "^Swap:" | awk '{ print $2 }')"
    ;;
  *)
    printf "-1"
    ;;
  esac
}

cmd_val_compare() {
  local cmd
  local expected_value
  local value
  local default_error
  local custom_error_msg

  cmd=${1}
  shift
  expected_value=${1}
  shift

  # eval is needed when there is a pipe in the command string
  value=$(eval "${cmd}")
  value=${value//$'\t'/ }
  default_error="ERROR: Incorrect value for command (${cmd}). Expected ${expected_value}; got ${value}"
  custom_error_msg=${1:-${default_error}}
  shift

  if [[ "${value}" != "${expected_value}" ]]; then
    echo "${custom_error_msg}"
    _ERROR_FOUND=1
  fi
}

cmd_val_contains() {
  local cmd
  local expected_value
  local value
  cmd=${1}
  shift
  expected_value=${1}
  shift

  # eval is needed when there are single quotes and double quotes in the command string.
  value=$(eval "${cmd}")
  if ! echo "${value}" | grep "${expected_value}" &> /dev/null; then
    echo "ERROR: '${expected_value}' not found in output of command '${cmd}'."
    echo "Got:"
    echo "${value}"
    echo
    _ERROR_FOUND=1
  fi
}

check_package_exist() {
  local package_name

  package_name=${1}
  shift
  if ! rpm -qa | grep "${package_name}" &> /dev/null; then
    echo "ERROR: ${package_name} is not found in 'rpm -qa'"
    _ERROR_FOUND=1
  fi
}

validate_rpms() {
  check_package_exist "gcc"
  check_package_exist "make"
}

validate_sysctl() {
  local sysctl_path
  local RAM_IN_BYTES
  local PAGE_SIZE

  echo
  echo "Verifying sysctl"
  sysctl_path="/sbin/sysctl"
  cmd_val_compare "${sysctl_path} kernel.msgmax --value" "65536"
  cmd_val_compare "${sysctl_path} kernel.msgmnb --value" "65536"
  cmd_val_compare "${sysctl_path} kernel.msgmni --value" "2048"
  cmd_val_compare "${sysctl_path} kernel.sem --value" "500 2048000 200 40960"
  cmd_val_compare "${sysctl_path} kernel.shmmni --value" "1024"
  cmd_val_compare "${sysctl_path} kernel.sysrq --value" "1"
  cmd_val_compare "${sysctl_path} net.core.netdev_max_backlog --value" "2000"
  cmd_val_compare "${sysctl_path} net.core.rmem_max --value" "4194304"
  cmd_val_compare "${sysctl_path} net.core.wmem_max --value" "4194304"
  cmd_val_compare "${sysctl_path} net.core.rmem_default --value" "4194304"
  cmd_val_compare "${sysctl_path} net.core.wmem_default --value" "4194304"
  cmd_val_compare "${sysctl_path} net.ipv4.tcp_rmem --value" "4096 4224000 16777216"
  cmd_val_compare "${sysctl_path} net.ipv4.tcp_wmem --value" "4096 4224000 16777216"
  cmd_val_compare "${sysctl_path} net.core.optmem_max --value" "4194304"
  cmd_val_compare "${sysctl_path} net.core.somaxconn --value" "10000"
  cmd_val_compare "${sysctl_path} net.ipv4.ip_forward --value" "0"
  cmd_val_compare "${sysctl_path} net.ipv4.tcp_congestion_control --value" "cubic"
  cmd_val_compare "${sysctl_path} net.core.default_qdisc --value" "fq_codel"
  cmd_val_compare "${sysctl_path} net.ipv4.tcp_mtu_probing --value" "0"
  cmd_val_compare "${sysctl_path} net.ipv4.conf.all.arp_filter --value" "1"
  cmd_val_compare "${sysctl_path} net.ipv4.conf.default.accept_source_route --value" "0"
  cmd_val_compare "${sysctl_path} net.ipv4.ip_local_port_range --value" "10000 65535"
  cmd_val_compare "${sysctl_path} net.ipv4.tcp_max_syn_backlog --value" "4096"
  cmd_val_compare "${sysctl_path} net.ipv4.tcp_syncookies --value" "1"
  cmd_val_compare "${sysctl_path} vm.overcommit_memory --value" "2"
  cmd_val_compare "${sysctl_path} vm.overcommit_ratio --value" "95"
  cmd_val_compare "${sysctl_path} vm.swappiness --value" "10"
  cmd_val_compare "${sysctl_path} vm.dirty_expire_centisecs --value" "500"
  cmd_val_compare "${sysctl_path} vm.dirty_writeback_centisecs --value" "100"
  cmd_val_compare "${sysctl_path} vm.zone_reclaim_mode --value" "0"

  # Validate the memory calculations
  RAM_IN_BYTES=$(get_ram b)
  PAGE_SIZE=$(getconf PAGE_SIZE)

  cmd_val_compare "${sysctl_path} vm.min_free_kbytes --value" "$((3 * RAM_IN_BYTES / 100 / 1024))"
  cmd_val_compare "${sysctl_path} kernel.shmall --value" "$((RAM_IN_BYTES / 2 / PAGE_SIZE))"
  cmd_val_compare "${sysctl_path} kernel.shmmax --value" "$((RAM_IN_BYTES / 2))"
  if ((RAM_IN_BYTES <= 68719476736)); then
    # If RAM is smaller than or equal to 64GB.
    cmd_val_compare "${sysctl_path} vm.dirty_background_ratio --value" "3"
    cmd_val_compare "${sysctl_path} vm.dirty_ratio --value" "10"
  else
    # If RAM is greater than 64GB.
    cmd_val_compare "${sysctl_path} vm.dirty_background_ratio --value" "0"
    cmd_val_compare "${sysctl_path} vm.dirty_ratio --value" "0"
    cmd_val_compare "${sysctl_path} vm.dirty_background_bytes --value" "1610612736"
    cmd_val_compare "${sysctl_path} vm.dirty_bytes --value" "4294967296"
  fi
}

validate_guc_settings() {
  local RAM_IN_MB
  local RAM_IN_GB
  local SWAP_IN_MB
  local vm_overcommit_ratio
  local gp_resource_group_memory_limit_x100
  local num_active_primary_segments
  local rg_perseg_mem
  local max_expected_concurrent_queries
  local statement_mem
  local max_statement_mem
  local statement_mem_with_unit
  local max_statement_mem_with_unit
  local gp_vmem
  local max_acting_primary_segments
  local gp_vmem_protect_limit

  echo
  echo "Verifying GUC settings for Greenplum"
  if ! (su - gpadmin -c "gpstate") &> /dev/null; then
    echo "ERROR: Greenplum is not running."
    _ERROR_FOUND=1
  fi

  RAM_IN_MB=$(get_ram m)
  RAM_IN_GB=$(get_ram g)
  SWAP_IN_MB=$(get_swap m)

  vm_overcommit_ratio=$(sysctl -n vm.overcommit_ratio)

  gp_resource_group_memory_limit_x100=$(su - gpadmin -c 'gpconfig -s gp_resource_group_memory_limit' | grep "^Master" | awk '{ printf $3 * 100 }')

  num_active_primary_segments=$(su - gpadmin -c "psql -d postgres -t -c \"select count(1) from gp_segment_configuration where content <> -1 and preferred_role = 'p'\"" | awk '{ printf $1 }')

  rg_perseg_mem=$((((RAM_IN_MB * vm_overcommit_ratio / 100) + SWAP_IN_MB) * gp_resource_group_memory_limit_x100 / 100 / num_active_primary_segments))

  max_expected_concurrent_queries=$(su - gpadmin -c "psql -d postgres -t -c \"SELECT concurrency FROM gp_toolkit.gp_resgroup_config where groupname = 'default_group'\"")

  statement_mem=$((rg_perseg_mem / max_expected_concurrent_queries))
  max_statement_mem=$((RAM_IN_MB / max_expected_concurrent_queries))

  # If statement_mem and max_statement_mem (in MB) equally divided by 1024, value will be division quotient and unit will be GB
  # If statement_mem and max_statement_mem (in MB) not equally divided by 1024, value will be same and unit will be MB
  statement_mem_with_unit=$([ $((statement_mem % 1024)) == 0 ] && echo "$((statement_mem / 1024))GB" || echo "${statement_mem}MB")
  max_statement_mem_with_unit=$([ $((max_statement_mem % 1024)) == 0 ] && echo "$((max_statement_mem / 1024))GB" || echo "${max_statement_mem}MB")

  mem_factor=170
  if [ ${RAM_IN_GB} -gt 256 ]; then
    mem_factor=117
  fi
  gp_vmem=$(((((SWAP_IN_MB + RAM_IN_MB) - (7680 + (5 / 100) * RAM_IN_MB)) / (mem_factor / 100))))
  max_acting_primary_segments=$(su - gpadmin -c "psql -d postgres -t -c \
    \"with hostnames as ( \
      select distinct hostname \
      from gp_segment_configuration \
      where content <> -1 order by hostname \
      limit 1), \
    content_ids as ( \
      select content \
      from gp_segment_configuration \
      where hostname in ( \
        select hostname \
        from hostnames ) \
      and preferred_role = 'p' \
      and content <> -1), \
    counts as ( \
      select count(content) as mirrors_per_host, hostname \
      from gp_segment_configuration \
      where content in ( \
        select content \
        from content_ids) \
      and preferred_role = 'm' \
      group by hostname) \
    select t.count + coalesce(s.max, 0) \
    from ( \
      select count(content) \
      from content_ids) t, ( \
      select max(mirrors_per_host) \
      from counts) s\"" | awk '{ printf $1 }')
  gp_vmem_protect_limit=$((gp_vmem / max_acting_primary_segments))

  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_interconnect_queue_depth'" "Master  value: 16"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_interconnect_queue_depth'" "Segment value: 16"

  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_interconnect_snd_queue_depth'" "Master  value: 16"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_interconnect_snd_queue_depth'" "Segment value: 16"

  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_resource_group_memory_limit'" "Master  value: 0.85"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_resource_group_memory_limit'" "Segment value: 0.85"

  cmd_val_contains "su - gpadmin -c 'gpconfig -s statement_mem'" "Master  value: ${statement_mem_with_unit}"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s statement_mem'" "Segment value: ${statement_mem_with_unit}"

  cmd_val_contains "su - gpadmin -c 'gpconfig -s max_statement_mem'" "Master  value: ${max_statement_mem_with_unit}"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s max_statement_mem'" "Segment value: ${max_statement_mem_with_unit}"

  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_vmem_protect_limit'" "Master  value: ${gp_vmem_protect_limit}"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_vmem_protect_limit'" "Segment value: ${gp_vmem_protect_limit}"

  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_workfile_compression'" "Master  value: off"
  cmd_val_contains "su - gpadmin -c 'gpconfig -s gp_workfile_compression'" "Segment value: off"

}

# stage 2 occurs when the VM first boots from the OVF template
validate() {
  validate_rpms
  validate_sysctl
  validate_guc_settings
}

_main() {
  export _ERROR_FOUND=0

  validate

  echo
  echo "TPC-DS pre-check validation complete"
  exit ${_ERROR_FOUND}
}

[[ "${BASH_SOURCE[0]}" = "${0}" ]] && _main
