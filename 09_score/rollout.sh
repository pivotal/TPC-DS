#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${PWD}/../functions.sh
source_bashrc

GEN_DATA_SCALE=$1; shift
EXPLAIN_ANALYZE=$1; shift
RANDOM_DISTRIBUTION=$1; shift
MULTI_USER_COUNT=$1; shift
SINGLE_USER_ITERATIONS=$1; shift

if [[ "${GEN_DATA_SCALE}" == "" || "${EXPLAIN_ANALYZE}" == "" || "${RANDOM_DISTRIBUTION}" == "" || "${MULTI_USER_COUNT}" == "" || "${SINGLE_USER_ITERATIONS}" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false false 5 1"
	exit 1
fi

STEP="score"
init_log ${STEP}

LOAD_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples > 0")
ANALYZE_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples = 0")
QUERIES_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from (SELECT split_part(description, '.', 2) AS id, min(duration) AS duration FROM tpcds_reports.sql GROUP BY split_part(description, '.', 2)) as sub")
CONCURRENT_QUERY_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_testing.sql")

S_Q=${MULTI_USER_COUNT}

# Calculate operands for v1.3.1 of the TPC-DS score
Q_1_3_1=$(( 3 * S_Q * 99 ))
TPT_1_3_1=$(( QUERIES_TIME * S_Q ))
TTT_1_3_1=$(( 2 * CONCURRENT_QUERY_TIME ))
TLD_1_3_1=$(( S_Q * LOAD_TIME / 100 ))

# Calculate operands for v2.2.0 of the TPC-DS score
Q_2_2_0=$(( S_Q * 99 ))
TPT_2_2_0=$(echo "${QUERIES_TIME} * ${S_Q} / 3600" | bc -l)
TTT_2_2_0=$(echo "2 * ${CONCURRENT_QUERY_TIME} / 3600" | bc -l)
TLD_2_2_0=$(echo "0.01 * ${S_Q} * ${LOAD_TIME} / 3600" | bc -l)

# Calculate scores using aggregation functions in psql
psql -v ON_ERROR_STOP=1 -q -t -A -c "drop table if exists tpc_ds_vals"
psql -v ON_ERROR_STOP=1 -q -t -A -c "create table tpc_ds_vals(v1_3_1 double precision, v2_2_0 double precision)"
TPTl -v ON_ERROR_STOP=1 -q -t -A -c "insert into tpc_ds_vals values(${TPT_1_3_1},${TPT_2_2_0}),(${TTT_1_3_1},${TTT_2_2_0}),(${TLD_1_3_1},${TLD_2_2_0})"
SCORE_1_3_1=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor(${Q_1_3_1} * ${GEN_DATA_SCALE} / sum(v1_3_1)) from tpc_ds_vals")
SCORE_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor(${Q_2_2_0} * ${GEN_DATA_SCALE} / exp(avg(ln(v2_2_0)))) from tpc_ds_vals")
psql -v ON_ERROR_STOP=1 -q -t -A -c "drop table tpc_ds_vals"

echo -e "Number of Streams (Sq)\t${S_Q}"
echo -e "Scale Factor (SF)\t${GEN_DATA_SCALE}"
echo -e "Load\t\t\t${LOAD_TIME}"
echo -e "Analyze\t\t\t${ANALYZE_TIME}"
echo -e "1 User Queries\t\t${QUERIES_TIME}"
echo -e "Concurrent Queries\t${CONCURRENT_QUERY_TIME}"
echo -e ""
echo -e "TPC-DS v1.3.1 (QphDS@SF = floor(SF * Q / sum(TPT, TTT, TLD)))"
echo -e "Q (3 * Sq * 99)\t\t${Q_1_3_1}"
echo -e "TPT (seconds)\t\t${TPT_1_3_1}"
echo -e "TTT (seconds)\t\t${TTT_1_3_1}"
echo -e "TLD (seconds)\t\t${TLD_1_3_1}"
echo -e "Score\t\t\t${SCORE_1_3_1}"
echo -e ""
echo -e "TPC-DS v2.2.0 (QphDS@SF = floor(SF * Q / geomean(TPT, TTT, TLD)))"
echo -e "Q (Sq * 99)\t\t${Q_2_2_0}"
printf "TPT (hours)\t\t%.3f\n" "${TPT_2_2_0}"
printf "TTT (hours)\t\t%.3f\n" "${TTT_2_2_0}"
printf "TLD (hours)\t\t%.3f\n" "${TLD_2_2_0}"
echo -e "Score\t\t\t${SCORE_2_2_0}"

end_step ${STEP}
