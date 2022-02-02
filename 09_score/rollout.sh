#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

GEN_DATA_SCALE=$1; shift
EXPLAIN_ANALYZE=$1; shift
RANDOM_DISTRIBUTION=$1; shift
MULTI_USER_COUNT=$1; shift
SINGLE_USER_ITERATIONS=$1; shift

if [[ "$GEN_DATA_SCALE" == "" || "$EXPLAIN_ANALYZE" == "" || "$RANDOM_DISTRIBUTION" == "" || "$MULTI_USER_COUNT" == "" || "$SINGLE_USER_ITERATIONS" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, true/false to use random distrbution, multi-user count, and the number of sql iterations."
	echo "Example: ./rollout.sh 100 false false 5 1"
	exit 1
fi

step="score"
init_log $step

load_time=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples > 0")
analyze_time=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples = 0")
queries_time=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from (SELECT split_part(description, '.', 2) AS id, min(duration) AS duration FROM tpcds_reports.sql GROUP BY split_part(description, '.', 2)) as sub")
concurrent_queries_time=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_testing.sql")

# Calculate operands for v1.3.1 of the TPC-DS score
q_1_3_1=$(( 3 * MULTI_USER_COUNT * 99 ))
tpt_1_3_1=$(( queries_time * MULTI_USER_COUNT ))
ttt_1_3_1=$(( 2 * concurrent_queries_time ))
tld_1_3_1=$(( MULTI_USER_COUNT * load_time / 100 ))

# Calculate operands for v2.2.0 of the TPC-DS score
q_2_2_0=$(( MULTI_USER_COUNT * 99 ))
tpt_2_2_0=$(echo "$queries_time * $MULTI_USER_COUNT / 3600" | bc -l)
ttt_2_2_0=$(echo "2 * $concurrent_queries_time / 3600" | bc -l)
tld_2_2_0=$(echo "0.01 * $MULTI_USER_COUNT * $load_time / 3600" | bc -l)

# Calculate scores using aggregation functions in psql
psql -v ON_ERROR_STOP=1 -q -t -A -c "drop table if exists tpc_ds_vals"
psql -v ON_ERROR_STOP=1 -q -t -A -c "create table tpc_ds_vals(v1_3_1 double precision, v2_2_0 double precision)"
psql -v ON_ERROR_STOP=1 -q -t -A -c "insert into tpc_ds_vals values($tpt_1_3_1,$tpt_2_2_0),($ttt_1_3_1,$ttt_2_2_0),($tld_1_3_1,$tld_2_2_0)"
score_1_3_1=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor($q_1_3_1 * $GEN_DATA_SCALE / sum(v1_3_1)) from tpc_ds_vals")
score_2_2_0=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select floor($q_2_2_0 * $GEN_DATA_SCALE / exp(avg(ln(v2_2_0)))) from tpc_ds_vals")
psql -v ON_ERROR_STOP=1 -q -t -A -c "drop table tpc_ds_vals"

echo -e "Number of Streams (Sq)\t$MULTI_USER_COUNT"
echo -e "Scale Factor (SF)\t$GEN_DATA_SCALE"
echo -e "Load\t\t\t$load_time"
echo -e "Analyze\t\t\t$analyze_time"
echo -e "1 User Queries\t\t$queries_time"
echo -e "Concurrent Queries\t$concurrent_queries_time"
echo -e ""
echo -e "TPC-DS v1.3.1 (QphDS@SF = floor(SF * Q / sum(TPT, TTT, TLD)))"
echo -e "Q (3 * Sq * 99)\t\t$q_1_3_1"
echo -e "TPT (seconds)\t\t$tpt_1_3_1"
echo -e "TTT (seconds)\t\t$ttt_1_3_1"
echo -e "TLD (seconds)\t\t$tld_1_3_1"
echo -e "Score\t\t\t$score_1_3_1"
echo -e ""
echo -e "TPC-DS v2.2.0 (QphDS@SF = floor(SF * Q / geomean(TPT, TTT, TLD)))"
echo -e "Q (Sq * 99)\t\t$q_2_2_0"
printf "TPT (hours)\t\t%.3f\n" "$tpt_2_2_0"
printf "TTT (hours)\t\t%.3f\n" "$ttt_2_2_0"
printf "TLD (hours)\t\t%.3f\n" "$tld_2_2_0"
echo -e "Score\t\t\t$score_2_2_0"

end_step $step
