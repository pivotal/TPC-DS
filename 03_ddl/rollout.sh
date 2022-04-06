#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$PWD"/../functions.sh
source_bashrc

GEN_DATA_SCALE="$1"
EXPLAIN_ANALYZE="$2"
RANDOM_DISTRIBUTION="$3"
MULTI_USER_COUNT="$4"
SINGLE_USER_ITERATIONS="$5"
BENCH_ROLE="$6"

if [[ "${GEN_DATA_SCALE}" == "" || "${EXPLAIN_ANALYZE}" == "" || "${RANDOM_DISTRIBUTION}" == "" || "${MULTI_USER_COUNT}" == "" || "${SINGLE_USER_ITERATIONS}" == "" || "${BENCH_ROLE}" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false false 5 1"
	exit 1
fi

step=ddl
init_log $step
get_version

filter="gpdb"

#Create tables
for i in "$PWD"/*."$filter".*.sql; do
	# shellcheck disable=SC2034
	# id used in log(): functions.sh
	id=$(echo "$i" | awk -F '.' '{print $1}')
	schema_name=$(echo "$i" | awk -F '.' '{print $2}')
	table_name=$(echo "$i" | awk -F '.' '{print $3}')
	start_log

	if [ "$filter" == "gpdb" ]; then
		if [ "$RANDOM_DISTRIBUTION" == "true" ]; then
			DISTRIBUTED_BY="DISTRIBUTED RANDOMLY"
		else
			for z in $(cat "$PWD"/distribution.txt); do
				table_name2=$(echo "$z" | awk -F '|' '{print $2}')
				if [ "$table_name2" == "$table_name" ]; then
					distribution=$(echo "$z" | awk -F '|' '{print $3}')
				fi
			done
			DISTRIBUTED_BY="DISTRIBUTED BY (""$distribution"")"
		fi
	else
		DISTRIBUTED_BY=""
	fi

	echo "psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f $i -v SMALL_STORAGE=\"$SMALL_STORAGE\" -v MEDIUM_STORAGE=\"$MEDIUM_STORAGE\" -v LARGE_STORAGE=\"$LARGE_STORAGE\" -v DISTRIBUTED_BY=\"$DISTRIBUTED_BY\""
	psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f "$i" -v SMALL_STORAGE="$SMALL_STORAGE" -v MEDIUM_STORAGE="$MEDIUM_STORAGE" -v LARGE_STORAGE="$LARGE_STORAGE" -v DISTRIBUTED_BY="$DISTRIBUTED_BY"

	log
done

#external tables are the same for all gpdb
get_gpfdist_port

for i in "$PWD"/*.ext_tpcds.*.sql; do
	start_log

	#id=$(echo "$i" | awk -F '.' '{print $1}') TODO delete later not used
	# shellcheck disable=SC2034
	# schema_name and table_name are used in log(): functions.sh
	schema_name=$(echo "$i" | awk -F '.' '{print $2}')
	# shellcheck disable=SC2034
	table_name=$(echo "$i" | awk -F '.' '{print $3}')

	counter=0

	if [ "$VERSION" == "gpdb_6" ]; then
		for x in $(psql -v ON_ERROR_STOP=1 -q -A -t -c "select rank() over(partition by g.hostname order by g.datadir), g.hostname from gp_segment_configuration g where g.content >= 0 and g.role = 'p' order by g.hostname"); do
			CHILD=$(echo "$x" | awk -F '|' '{print $1}')
			EXT_HOST=$(echo "$x" | awk -F '|' '{print $2}')
			PORT=$(($GPFDIST_PORT + $CHILD))

			if [ "$counter" -eq "0" ]; then
				LOCATION="'"
			else
				LOCATION+="', '"
			fi
			LOCATION+="gpfdist://${EXT_HOST}:${PORT}/${table_name}_[0-9]*_[0-9]*.dat"

			counter=$(($counter + 1))
		done
	else
		for x in $(psql -v ON_ERROR_STOP=1 -q -A -t -c "select rank() over (partition by g.hostname order by p.fselocation), g.hostname from gp_segment_configuration g join pg_filespace_entry p on g.dbid = p.fsedbid join pg_tablespace t on t.spcfsoid = p.fsefsoid where g.content >= 0 and g.role = 'p' and t.spcname = 'pg_default' order by g.hostname"); do
			CHILD=$(echo "$x" | awk -F '|' '{print $1}')
			EXT_HOST=$(echo "$x" | awk -F '|' '{print $2}')
			PORT=$(($GPFDIST_PORT + $CHILD))

			if [ "$counter" -eq "0" ]; then
				LOCATION="'"
			else
				LOCATION+="', '"
			fi
			LOCATION+="gpfdist://${EXT_HOST}:${PORT}/${table_name}_[0-9]*_[0-9]*.dat"

			counter=$(($counter + 1))
		done
	fi
	LOCATION+="'"

	echo "psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f $i -v LOCATION=\"$LOCATION\""
	psql -v ON_ERROR_STOP=1 -q -a -P pager=off -f "$i" -v LOCATION="$LOCATION"

	log
done

Qquery="select count(1) from gp_toolkit.gp_resqueue_status where rsqname = '${BENCH_ROLE}'"
CreateQueue="CREATE RESOURCE QUEUE ${BENCH_ROLE} WITH (ACTIVE_STATEMENTS=$(( $MULTI_USER_COUNT + 1 )))"
AlterQueue="ALTER RESOURCE QUEUE ${BENCH_ROLE} WITH (ACTIVE_STATEMENTS=$(( $MULTI_USER_COUNT + 1 )))"
DropRole="DROP ROLE IF EXISTS ${BENCH_ROLE}"
CreateRole="CREATE ROLE ${BENCH_ROLE} WITH RESOURCE QUEUE ${BENCH_ROLE}"
GrantSchemaPrivileges="GRANT ALL PRIVILEGES ON SCHEMA tpcds TO ${BENCH_ROLE}"
GrantTablePrivileges="GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA tpcds TO ${BENCH_ROLE}"

if [ "$(psql -v ON_ERROR_STOP=0 -t -q -P pager=off -c "${Qquery}")" -eq 0 ]; then
	echo "Creating Resource Queue: ${BENCH_ROLE}"
	psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${CreateQueue}"
else
	echo "Resource Queue, ${BENCH_ROLE}, already exists"
	echo "Altering Resource Queue: ${BENCH_ROLE}"
	psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${AlterQueue}"
fi

echo "Dropping role ${BENCH_ROLE} if it exists"
psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${DropRole}"
echo "Creating role ${BENCH_ROLE}"
psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${CreateRole}"
echo "Grant schema privileges to role ${BENCH_ROLE}"
psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${GrantSchemaPrivileges}"
echo "Grant table privileges to role ${BENCH_ROLE}"
psql -v ON_ERROR_STOP=0 -q -P pager=off -c "${GrantTablePrivileges}"

echo "Finished $step"
