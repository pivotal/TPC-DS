#!/bin/bash
set -e

count=$(alias | grep -cw grep || true)
if [ "$count" -gt "0" ]; then
  unalias grep
fi
count=$(alias | grep -cw ls || true)
if [ "$count" -gt "0" ]; then
  unalias ls
fi

export LD_PRELOAD=/lib64/libz.so.1 ps
# shellcheck disable=SC2034 #variables used in different functions
# LOCAL_PWD used in rollout.sh, ADMIN_USER used in tpcds.sh, MASTER_HOST used in 02_init/rollout.sh
# ADMIN_HOME used in 00_*/rollout.sh
LOCAL_PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#OSVERSION=$(uname)
# shellcheck disable=SC2034 #variables used in different functions
ADMIN_USER=$(whoami)
# shellcheck disable=SC2034 #variables used in different functions
ADMIN_HOME=$(eval echo ~"$ADMIN_USER")
# shellcheck disable=SC2034 #variables used in different functions
MASTER_HOST=$(hostname -s)

get_gpfdist_port()
{
  all_ports=$(psql -t -A -c "select min(case when role = 'p' then port else 999999 end), min(case when role = 'm' then port else 999999 end) from gp_segment_configuration where content >= 0")
  primary_base=$(echo "$all_ports" | awk -F '|' '{print $1}' | head -c1)
  mirror_base=$(echo "$all_ports" | awk -F '|' '{print $2}' | head -c1)

  for i in $(seq 4 9); do
    if [ "$primary_base" -ne "$i" ] && [ "$mirror_base" -ne "$i" ]; then
      # shellcheck disable=SC2034
      # used in 04_load/start_gpfdist.sh,04_load/rollout.sh
      GPFDIST_PORT="$i""000"
      break
    fi
  done
}

source_bashrc()
{
  if [ -f "$HOME/.bashrc" ]; then
    # don't fail if an error is happening in the admin's profile
    source "$HOME/.bashrc" || true
  fi
  count=$(grep -v "^#" "$HOME/.bashrc" | grep -c "greenplum_path" || true)
  if [ "$count" -eq "0" ]; then
    get_version
    if [[ "$VERSION" == *"gpdb"* ]]; then
      echo "$HOME/.bashrc does not contain greenplum_path.sh"
      echo "Please update your $HOME/.bashrc for $ADMIN_USER and try again."
      exit 1
    fi
  fi
}

get_version()
{
  #need to call source_bashrc first
  VERSION=$(psql -v ON_ERROR_STOP=1 -t -A -c "SELECT CASE WHEN POSITION ('Greenplum Database 4.3' IN version) > 0 THEN 'gpdb_4_3' WHEN POSITION ('Greenplum Database 5' IN version) > 0 THEN 'gpdb_5' WHEN POSITION ('Greenplum Database 6' IN version) > 0 THEN 'gpdb_6' ELSE 'postgresql' END FROM version();") 
  if [[ "$VERSION" == *"gpdb"* ]]; then
    quicklz_test=$(psql -v ON_ERROR_STOP=1 -t -A -c "SELECT COUNT(*) FROM pg_compression WHERE compname = 'quicklz'")
    if [ "$quicklz_test" -eq "1" ]; then
      SMALL_STORAGE="appendonly=true, orientation=column"
      MEDIUM_STORAGE="appendonly=true, orientation=column"
      LARGE_STORAGE="appendonly=true, orientation=column, compresstype=quicklz"
    else
      SMALL_STORAGE="appendonly=true, orientation=column"
      MEDIUM_STORAGE="appendonly=true, orientation=column"
      LARGE_STORAGE="appendonly=true, orientation=column, compresstype=zlib, compresslevel=4"
    fi
  else
    # shellcheck disable=SC2034
    # used in 03_ddl/rollout.sh, 03_ddl/*.sql
    SMALL_STORAGE=""
    # shellcheck disable=SC2034
    MEDIUM_STORAGE=""
    # shellcheck disable=SC2034
    LARGE_STORAGE=""
  fi
}

init_log()
{
  logfile=rollout_"$1".log
  rm -f "${LOCAL_PWD}/log/${logfile}"
}

start_log()
{
  T_START="$(date +%s)"
}

log()
{
  #duration
  T_END="$(date +%s)"
  T_DURATION="$((T_END-T_START))"
  S_DURATION=$T_DURATION

  #this is done for steps that don't have id values
  if [ "$id" == "" ]; then
    id="1"
  else
    id=$(basename "$i" | awk -F '.' '{print $1}')
  fi

  tuples="$1"
  if [ "$tuples" == "" ]; then
    tuples="0"
  fi
  # shellcheck disable=SC2154
  # calling function adds schema_name and table_name
  printf "$id|$schema_name.$table_name|$tuples|%02d:%02d:%02d|%d|%d\n" "$((S_DURATION/3600%24))" "$((S_DURATION/60%60))" "$((S_DURATION%60))" "${T_START}" "${T_END}" >> "${LOCAL_PWD}/log/${logfile}"
}

end_step()
{
  local logfile=end_$1.log
  touch "$LOCAL_PWD/log/$logfile"
}

create_hosts_file()
{
  get_version

  psql -v ON_ERROR_STOP=1 -t -A -c "SELECT DISTINCT hostname FROM gp_segment_configuration WHERE role = 'p' AND content >= 0" -o "$LOCAL_PWD"/segment_hosts.txt
}
