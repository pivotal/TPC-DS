#!/bin/bash
set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")

step="load"
init_log "${step}"

get_version
filter="gpdb"

function copy_script() {
  echo "copy the start and stop scripts to the segment hosts in the cluster"
  while IFS= read -r i; do
    echo "scp start_gpfdist.sh stop_gpfdist.sh ${i}:"
    scp "${PWD}"/start_gpfdist.sh "${PWD}"/stop_gpfdist.sh "${i}": &
  done < "${TPC_DS_DIR}"/segment_hosts.txt
  wait
}

function stop_gpfdist() {
  echo "stop gpfdist on all ports"
  while IFS= read -r i; do
    ssh -n -f "${i}" "bash -c 'cd ~/; ./stop_gpfdist.sh'" &
  done < "${TPC_DS_DIR}"/segment_hosts.txt
  wait
}

function start_gpfdist() {
  stop_gpfdist
  sleep 1
  get_gpfdist_port

  if [ "${VERSION}" == "gpdb_6" ] || [ "${VERSION}" == "gpdb_7" ]; then
    SQL_QUERY="select rank() over(partition by g.hostname order by g.datadir), g.hostname, g.datadir from gp_segment_configuration g where g.content >= 0 and g.role = '${GPFDIST_LOCATION}' order by g.hostname"
  else
    SQL_QUERY="select rank() over (partition by g.hostname order by p.fselocation), g.hostname, p.fselocation as path from gp_segment_configuration g join pg_filespace_entry p on g.dbid = p.fsedbid join pg_tablespace t on t.spcfsoid = p.fsefsoid where g.content >= 0 and g.role = '${GPFDIST_LOCATION}' and t.spcname = 'pg_default' order by g.hostname"
  fi
  for i in $(psql -v ON_ERROR_STOP=1 -q -A -t -c "${SQL_QUERY}"); do
    CHILD=$(echo "${i}" | awk -F '|' '{print $1}')
    EXT_HOST=$(echo "${i}" | awk -F '|' '{print $2}')
    GEN_DATA_PATH=$(echo "${i}" | awk -F '|' '{print $3}')
    GEN_DATA_PATH="${GEN_DATA_PATH}/dsbenchmark"
    PORT=$((GPFDIST_PORT + CHILD))
    echo "executing on ${EXT_HOST} ./start_gpfdist.sh $PORT ${GEN_DATA_PATH}"
    ssh -n -f "${EXT_HOST}" "bash -c 'cd ~${ADMIN_USER}; ./start_gpfdist.sh $PORT ${GEN_DATA_PATH}'" &
  done
  wait
}

copy_script
start_gpfdist

# need to wait for all the gpfdist processes to start
sleep 5

# truncate table
echo "truncating all tables ..."
psql -v ON_ERROR_STOP=1 -f "${PWD}/000.truncate.tables.sql"
echo "finished truncate ..."

for i in "${PWD}"/*."${filter}".*.sql; do
  start_log

  id=$(basename "${i}" | awk -F '.' '{print $1}')
  schema_name=$(basename "${i}" | awk -F '.' '{print $2}')
  table_name=$(basename "${i}" | awk -F '.' '{print $3}')

  log_time "psql -v ON_ERROR_STOP=1 -f ${i} | grep INSERT | awk -F ' ' '{print \$3}'"
  tuples=$(
    psql -v ON_ERROR_STOP=1 -f "${i}" | grep INSERT | awk -F ' ' '{print $3}'
    exit "${PIPESTATUS[0]}"
  )

  print_log "${id}" "${schema_name}" "${table_name}" "${tuples}"
done

log_time "finished loading tables"
print_log "${id}" "${schema_name}" "${table_name}" 0

stop_gpfdist

dbname="$PGDATABASE"
if [ "${dbname}" == "" ]; then
  dbname="${ADMIN_USER}"
fi

if [ "${PGPORT}" == "" ]; then
  export PGPORT=5432
fi

schema_name="tpcds"
table_name="tpcds"

start_log
#Analyze schema using analyzedb
analyzedb -d "${dbname}" -s "${schema_name}" --full -a

#make sure root stats are gathered
if [ "${VERSION}" == "gpdb_7" ]; then
  SQL_QUERY="select distinct n.nspname, c.relname from pg_partitioned_table pt left join pg_class c on pt.partrelid = c.oid left join pg_namespace n on c.relnamespace = n.oid where c.relkind = 'p' and n.nspname = 'tpcds';"
elif [ "${VERSION}" == "gpdb_6" ]; then
  SQL_QUERY="select n.nspname, c.relname from pg_class c join pg_namespace n on c.relnamespace = n.oid left outer join (select starelid from pg_statistic group by starelid) s on c.oid = s.starelid join (select tablename from pg_partitions group by tablename) p on p.tablename = c.relname where n.nspname = 'tpcds' and s.starelid is not null order by 1, 2"
else
  SQL_QUERY="select n.nspname, c.relname from pg_class c join pg_namespace n on c.relnamespace = n.oid join pg_partitions p on p.schemaname = n.nspname and p.tablename = c.relname where n.nspname = 'tpcds' and p.partitionrank is null and c.reltuples = 0 order by 1, 2"
fi
for t in $(psql -v ON_ERROR_STOP=1 -q -t -A -c "${SQL_QUERY}"); do
  schema_name=$(echo "${t}" | awk -F '|' '{print $1}')
  table_name=$(echo "${t}" | awk -F '|' '{print $2}')
  echo "Missing root stats for ${schema_name}.${table_name}"
  SQL_QUERY="ANALYZE ROOTPARTITION ${schema_name}.${table_name}"
  log_time "psql -v ON_ERROR_STOP=1 -q -t -A -c \"${SQL_QUERY}\""
  psql -v ON_ERROR_STOP=1 -q -t -A -c "${SQL_QUERY}"
done

max_id=$(find "${PWD}" -name "*.sql" | sort | tail -1)
id=$(basename "${max_id}" | awk -F '.' '{print $1}' | sed 's/^0*//')
print_log "${id}" "${schema_name}" "${table_name}" 0

echo "Finished ${step}"
