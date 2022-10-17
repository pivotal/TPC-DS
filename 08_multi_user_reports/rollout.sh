#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})
step="multi_user_reports"

init_log ${step}

get_version
filter="gpdb"

for i in ${PWD}/*.${filter}.*.sql; do
	log_time "psql -v ON_ERROR_STOP=1 -a -f ${i}"
	psql -v ON_ERROR_STOP=1 -a -f ${i}
	echo ""
done

filename=$(ls ${PWD}/*.copy.*.sql)

for i in ${TPC_DS_DIR}/log/rollout_testing_*; do
	logfile="'${i}'"
	log_time "psql -v ON_ERROR_STOP=1 -a -f ${filename} -v LOGFILE=\"${logfile}\""
	psql -v ON_ERROR_STOP=1 -a -f ${filename} -v LOGFILE="${logfile}"
done

psql -v ON_ERROR_STOP=1 -t -A -c "select 'analyze ' || n.nspname || '.' || c.relname || ';' from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'tpcds_testing'" | psql -v ON_ERROR_STOP=1 -t -A -e

psql -v ON_ERROR_STOP=1 -F $'\t' -A -P pager=off -f ${PWD}/detailed_report.sql
echo ""

echo "Finished ${step}"
