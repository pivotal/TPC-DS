#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

step="sql"
init_log ${step}

rm -f ${TPC_DS_DIR}/log/*single.explain_analyze.log
for i in ${PWD}/*.${BENCH_ROLE}.*.sql; do
	for x in $(seq 1 ${SINGLE_USER_ITERATIONS}); do
		id=$(echo ${i} | awk -F '.' '{print $1}')
		schema_name=$(echo ${i} | awk -F '.' '{print $2}')
		table_name=$(echo ${i} | awk -F '.' '{print $3}')
		start_log
		if [ "${EXPLAIN_ANALYZE}" == "false" ]; then
			log_time "psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE=\"\" -f ${i} | wc -l"
			tuples=$(psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="" -f ${i} | wc -l; exit ${PIPESTATUS[0]})
		else
			myfilename=$(basename ${i})
			mylogfile=${TPC_DS_DIR}/log/${myfilename}.single.explain_analyze.log
			log_time "psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE=\"EXPLAIN ANALYZE\" -f ${i} > ${mylogfile}"
			psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="EXPLAIN ANALYZE" -f ${i} > ${mylogfile}
			tuples="0"
		fi
		print_log ${tuples}
	done
done

echo "Finished ${step}"
