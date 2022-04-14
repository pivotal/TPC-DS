#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$PWD"/../functions.sh
source_bashrc

GEN_DATA_SCALE="${1}"
EXPLAIN_ANALYZE="${2}"
RANDOM_DISTRIBUTION="${3}"
MULTI_USER_COUNT="${4}"
SINGLE_USER_ITERATIONS="${5}"
BENCH_ROLE="${6}"

if [[ "${GEN_DATA_SCALE}" == "" || "${EXPLAIN_ANALYZE}" == "" || "${RANDOM_DISTRIBUTION}" == "" || "${MULTI_USER_COUNT}" == "" || "${SINGLE_USER_ITERATIONS}" == ""  || "${BENCH_ROLE}" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false false 5 1"
	exit 1
fi

step=sql
init_log $step

rm -f "$PWD"/../log/*single.explain_analyze.log
for i in "$PWD"/*."${BENCH_ROLE}".*.sql; do
	for (( n=1; n < "${SINGLE_USER_ITERATIONS}"; n++)); do
		# shellcheck disable=SC2034
		# id, schema_name and table_name are used in log(): functions.sh
		id=$(echo "$i" | awk -F '.' '{print $1}')
		# shellcheck disable=SC2034
		schema_name=$(echo "$i" | awk -F '.' '{print $2}')
		# shellcheck disable=SC2034
		table_name=$(echo "$i" | awk -F '.' '{print $3}')
		start_log
		if [ "${EXPLAIN_ANALYZE}" == "false" ]; then
			echo "psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE=\"\" -f $i | wc -l"
			tuples=$(psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="" -f "$i" | wc -l; exit "${PIPESTATUS[0]}")
		else
			myfilename=$(basename "$i")
			mylogfile="$PWD"/../log/$myfilename.single.explain_analyze.log
			echo "psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE=\"EXPLAIN ANALYZE\" -f $i > $mylogfile"
			psql -v ON_ERROR_STOP=1 -A -q -t -P pager=off -v EXPLAIN_ANALYZE="EXPLAIN ANALYZE" -f "$i" > "$mylogfile"
			tuples="0"
		fi
		log "$tuples"
	done
done

echo "Finished $step"
