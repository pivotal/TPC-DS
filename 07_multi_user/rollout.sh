#!/bin/bash

set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

if [ "${MULTI_USER_COUNT}" -eq "0" ]; then
	echo "MULTI_USER_COUNT set at 0 so exiting..."
	exit 0
fi

function get_psql_count()
{
	psql_count=$(ps -ef | grep psql | grep multi_user | grep -v grep | wc -l)
}

function get_file_count()
{
	file_count=$(ls ${TPC_DS_DIR}/log/end_testing* 2> /dev/null | wc -l)
}


rm -f ${TPC_DS_DIR}/log/end_testing_*.log
rm -f ${TPC_DS_DIR}/log/testing*.log
rm -f ${TPC_DS_DIR}/log/rollout_testing_*.log
rm -f ${TPC_DS_DIR}/log/*multi.explain_analyze.log

function generate_templates()
{
	rm -f ${PWD}/query_*.sql

	#create each user's directory
	sql_dir=${PWD}
	echo "sql_dir: ${sql_dir}"
	for i in $(seq 1 ${MULTI_USER_COUNT}); do
		sql_dir="${PWD}/${i}"
		echo "checking for directory ${sql_dir}"
		if [ ! -d "${sql_dir}" ]; then
			echo "mkdir ${sql_dir}"
			mkdir ${sql_dir}
		fi
		echo "rm -f ${sql_dir}/*.sql"
		rm -f ${sql_dir}/*.sql
	done

	#Create queries
	echo "cd ${PWD}"
	cd ${PWD}
	log_time "${PWD}/dsqgen -streams ${MULTI_USER_COUNT} -input ${PWD}/query_templates/templates.lst -directory ${PWD}/query_templates -dialect pivotal -scale ${GEN_DATA_SCALE} -verbose y -output ${PWD}"
	${PWD}/dsqgen -streams ${MULTI_USER_COUNT} -input ${PWD}/query_templates/templates.lst -directory ${PWD}/query_templates -dialect pivotal -scale ${GEN_DATA_SCALE} -verbose y -output ${PWD}

	#move the query_x.sql file to the correct session directory
	for i in ${PWD}/query_*.sql; do
		stream_number=$(basename ${i} | awk -F '.' '{print $1}' | awk -F '_' '{print $2}')
		#going from base 0 to base 1
		stream_number=$((stream_number + 1))
		echo "stream_number: ${stream_number}"
		sql_dir=${PWD}/${stream_number}
		echo "mv ${i} ${sql_dir}/"
		mv ${i} ${sql_dir}/
	done
}

if [ "${RUN_QGEN}" = "true" ]; then
  generate_templates
fi

for session_id in $(seq 1 ${MULTI_USER_COUNT}); do
	session_log=${TPC_DS_DIR}/log/testing_session_${session_id}.log
	log_time "${PWD}/test.sh ${session_id}"
	${PWD}/test.sh ${session_id} > ${session_log} 2>&1 < ${session_log} &
done

sleep 60
get_psql_count
echo "Now executing queries. This may take a while."
minutes=0
echo -ne "Multi-user query duration: "
tput sc
while [ "${psql_count}" -gt "0" ]; do
	tput rc
	echo -ne "${minutes} minute(s)"
	sleep 60
	minutes=$((minutes + 1))
	get_psql_count
done
echo ""
echo "done."
echo ""

get_file_count

if [ "${file_count}" -ne "${MULTI_USER_COUNT}" ]; then
	echo "The number of successfully completed sessions is less than expected!"
	echo "Please review the log files to determine which queries failed."
	exit 1
fi

rm -f ${TPC_DS_DIR}/log/end_testing_*.log # remove the counter log file if successful.
