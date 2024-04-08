#!/bin/bash

set -e

PWD=$(get_pwd "${BASH_SOURCE[0]}")

max_id=$(find "${PWD}" -name "*.sql" -prune | sort -n | tail -1)
max_id=$(basename "${max_id}" | awk -F '.' '{print $1}')

dbname="${PGDATABASE}"
if [ "${dbname}" == "" ]; then
  dbname="$ADMIN_USER"
fi

if [ "${PGPORT}" == "" ]; then
  export PGPORT=5432
fi

start_log
id=${max_id}
schema_name="tpcds"
table_name="tpcds"
analyzedb -d "${dbname}" -s tpcds --full -a
print_log "${id}" "${schema_name}" "${table_name}" "0"
