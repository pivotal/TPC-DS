#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

step="single_user_reports"

init_log ${step}

filter="gpdb"

for i in ${PWD}/*.${filter}.*.sql; do
	log_time "psql -v ON_ERROR_STOP=1 -a -f ${i}"
	psql -v ON_ERROR_STOP=1 -a -f ${i}
	echo ""
done

for i in ${PWD}/*.copy.*.sql; do
	logstep=$(echo ${i} | awk -F 'copy.' '{print $2}' | awk -F '.' '{print $1}')
	logfile="${TPC_DS_DIR}/log/rollout_${logstep}.log"
	logfile="'${logfile}'"
	log_time "psql -v ON_ERROR_STOP=1 -a -f ${i} -v LOGFILE=\"${logfile}\""
	psql -v ON_ERROR_STOP=1 -a -f ${i} -v LOGFILE="${logfile}"
	echo ""
done

psql -v ON_ERROR_STOP=1 -q -t -A -c "select 'analyze ' || n.nspname || '.' || c.relname || ';' from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'tpcds_reports'" | psql -v ON_ERROR_STOP=1 -t -A -e

echo "********************************************************************************"
echo "Generate Data"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/gen_data_report.sql
echo ""
echo "********************************************************************************"
echo "Data Loads"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/loads_report.sql
echo ""
echo "********************************************************************************"
echo "Analyze"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/analyze_report.sql
echo ""
echo ""
echo "********************************************************************************"
echo "Queries"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/queries_report.sql
echo ""
echo "Finished ${step}"
