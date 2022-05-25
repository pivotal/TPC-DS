#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

step="score"
init_log ${step}

LOAD_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples > 0")
ANALYZE_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples = 0")
QUERIES_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from (SELECT split_part(description, '.', 2) AS id, min(duration) AS duration FROM tpcds_reports.sql GROUP BY split_part(description, '.', 2)) as sub")
CONCURRENT_QUERY_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_testing.sql")
THROUGHPUT_ELAPSED_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select max(end_epoch_seconds) - min(start_epoch_seconds) from tpcds_testing.sql")

S_Q=${MULTI_USER_COUNT}
SF=${GEN_DATA_SCALE}

# Calculate operands for v1.3.1 of the TPC-DS score
Q_1_3_1=$(( 3 * S_Q * 99 ))
TPT_1_3_1=$(( QUERIES_TIME * S_Q ))
TTT_1_3_1=$(( 2 * CONCURRENT_QUERY_TIME ))
TLD_1_3_1=$(( S_Q * LOAD_TIME / 100 ))

# Calculate operands for v2.2.0 of the TPC-DS score
Q_2_2_0=$(( S_Q * 99 ))
TPT_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select cast(${QUERIES_TIME} as decimal) * cast(${S_Q} as decimal) / cast(3600.0 as decimal)")
TTT_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select cast(2 as decimal) * cast(${THROUGHPUT_ELAPSED_TIME} as decimal) / cast(3600.0 as decimal)")
TLD_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select cast(0.01 as decimal) * cast(${S_Q} as decimal) * cast(${LOAD_TIME} as decimal) / cast(3600.0 as decimal)")

# Calculate scores using aggregation functions in psql
SCORE_1_3_1=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor(cast(${Q_1_3_1} as decimal) * cast(${SF} as decimal) / (cast(${TPT_1_3_1} as decimal) + cast(${TTT_1_3_1} as decimal) + cast(${TLD_1_3_1} as decimal)))")
SCORE_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor(cast(${Q_2_2_0} as decimal) * cast(${SF} as decimal) / exp((ln(cast(${TPT_2_2_0} as decimal)) + ln(cast(${TTT_2_2_0} as decimal)) + ln(cast(${TLD_2_2_0} as decimal))) / cast(3.0 as decimal)))")

printf "Number of Streams (Sq)\t%d\n" "${S_Q}"
printf "Scale Factor (SF)\t%d\n" "${SF}"
printf "Load\t\t\t%d\n" "${LOAD_TIME}"
printf "Analyze\t\t\t%d\n" "${ANALYZE_TIME}"
printf "1 User Queries\t\t%d\n" "${QUERIES_TIME}"
printf "Concurrent Queries\t%d\n" "${CONCURRENT_QUERY_TIME}"
printf "Throughput Test Elapsed Time\t%d\n" "${THROUGHPUT_ELAPSED_TIME}"
printf "\n"
printf "TPC-DS v1.3.1 (QphDS@SF = floor(SF * Q / sum(TPT, TTT, TLD)))\n"
printf "Q (3 * Sq * 99)\t\t%d\n" "${Q_1_3_1}"
printf "TPT (seconds)\t\t%d\n" "${TPT_1_3_1}"
printf "TTT (seconds)\t\t%d\n" "${TTT_1_3_1}"
printf "TLD (seconds)\t\t%d\n" "${TLD_1_3_1}"
printf "Score\t\t\t%d\n" "${SCORE_1_3_1}"
printf "\n"
printf "TPC-DS v2.2.0 (QphDS@SF = floor(SF * Q / geomean(TPT, TTT, TLD)))\n"
printf "Q (Sq * 99)\t\t%d\n" "${Q_2_2_0}"
printf "TPT (hours)\t\t%.3f\n" "${TPT_2_2_0}"
printf "TTT (hours)\t\t%.3f\n" "${TTT_2_2_0}"
printf "TLD (hours)\t\t%.3f\n" "${TLD_2_2_0}"
printf "Score\t\t\t%d\n" "${SCORE_2_2_0}"

echo "Finished ${step}"
