#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")

step="init"
init_log "${step}"
start_log
schema_name="tpcds"
table_name="init"

function set_segment_bashrc() {
  #this is only needed if the segment nodes don't have the bashrc file created
  cat > "${PWD}"/segment_bashrc << EOF
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi
source /usr/local/greenplum-db/greenplum_path.sh
export LD_PRELOAD=${LD_PRELOAD}
EOF
  chmod 755 "${PWD}"/segment_bashrc

  echo "set up .bashrc on segment hosts"
  while IFS= read -r ext_host; do
    # don't overwrite the master.  Only needed on single node installs
    shortname=$(echo "${ext_host}" | awk -F '.' '{print $1}')
    if [ "${MASTER_HOST}" != "${shortname}" ]; then
      bashrc_exists=$(ssh -q -n "${ext_host}" "find ~ -name .bashrc | grep -c .")
      if [ "${bashrc_exists}" -eq 0 ]; then
        echo "copy new .bashrc to ${ext_host}:~${ADMIN_USER}"
        scp -q "${PWD}"/segment_bashrc "${ext_host}":~"${ADMIN_USER}"/.bashrc
      else
        count=$(ssh -q -n "${ext_host}" "grep -c greenplum_path ~/.bashrc || true")
        if [ "${count}" -eq 0 ]; then
          echo "Adding greenplum_path to ${ext_host} .bashrc"
          # shellcheck disable=SC2029
          ssh -q "${ext_host}" "echo \"source ${GREENPLUM_PATH}\" >> ~/.bashrc"
        fi
        count=$(ssh -q -n "${ext_host}" "grep -c LD_PRELOAD ~/.bashrc || true")
        if [ "${count}" -eq 0 ]; then
          echo "Adding LD_PRELOAD to ${ext_host} .bashrc"
          # shellcheck disable=SC2029
          ssh -q "${ext_host}" "echo \"export LD_PRELOAD=${LD_PRELOAD}\" >> ~/.bashrc"
        fi
      fi
    fi
  done < "${TPC_DS_DIR}"/segment_hosts.txt
}

function check_gucs() {
  update_config="0"

  if [ "${VERSION}" == "gpdb_5" ]; then
    counter=$(
      psql -v ON_ERROR_STOP=1 -q -t -A -c "show optimizer_join_arity_for_associativity_commutativity" | grep -ci "18" || true
      exit "${PIPESTATUS[0]}"
    )
    if [ "${counter}" -eq "0" ]; then
      echo "setting optimizer_join_arity_for_associativity_commutativity"
      gpconfig -c optimizer_join_arity_for_associativity_commutativity -v 18 --skipvalidation
      update_config="1"
    fi
  fi

  echo "check optimizer"
  counter=$(
    psql -v ON_ERROR_STOP=1 -q -t -A -c "show optimizer" | grep -ci "on" || true
    exit "${PIPESTATUS[0]}"
  )
  if [ "${counter}" -eq "0" ]; then
    echo "enabling optimizer"
    gpconfig -c optimizer -v on --masteronly
    update_config="1"
  fi

  echo "check analyze_root_partition"
  counter=$(
    psql -v ON_ERROR_STOP=1 -q -t -A -c "show optimizer_analyze_root_partition" | grep -ci "on" || true
    exit "${PIPESTATUS[0]}"
  )
  if [ "${counter}" -eq "0" ]; then
    echo "enabling analyze_root_partition"
    gpconfig -c optimizer_analyze_root_partition -v on --masteronly
    update_config="1"
  fi

  echo "check gp_autostats_mode"
  counter=$(
    psql -v ON_ERROR_STOP=1 -q -t -A -c "show gp_autostats_mode" | grep -ci "none" || true
    exit "${PIPESTATUS[0]}"
  )
  if [ "${counter}" -eq "0" ]; then
    echo "changing gp_autostats_mode to none"
    gpconfig -c gp_autostats_mode -v none --masteronly
    update_config="1"
  fi

  echo "check default_statistics_target"
  counter=$(
    psql -v ON_ERROR_STOP=1 -q -t -A -c "show default_statistics_target" | grep -c "100" || true
    exit "${PIPESTATUS[0]}"
  )
  if [ "${counter}" -eq "0" ]; then
    echo "changing default_statistics_target to 100"
    gpconfig -c default_statistics_target -v 100
    update_config="1"
  fi

  if [ "$update_config" -eq "1" ]; then
    echo "update cluster because of config changes"
    gpstop -u
  fi
}

function copy_config() {
  echo "copy config files"
  if [ "${MASTER_DATA_DIRECTORY}" != "" ]; then
    cp "${MASTER_DATA_DIRECTORY}"/pg_hba.conf "${TPC_DS_DIR}"/log/
    cp "${MASTER_DATA_DIRECTORY}"/postgresql.conf "${TPC_DS_DIR}"/log/
  fi
  #gp_segment_configuration
  psql -v ON_ERROR_STOP=1 -q -A -t -c "SELECT * FROM gp_segment_configuration" -o "${TPC_DS_DIR}"/log/gp_segment_configuration.txt
}

get_version
set_segment_bashrc
check_gucs
copy_config

print_log "1" "${schema_name}" "${table_name}" "0"

echo "Finished ${step}"
