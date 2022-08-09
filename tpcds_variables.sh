# shellcheck disable=SC2148
# environment options
export ADMIN_USER="gpadmin"
export BENCH_ROLE="dsbench"

# to connect directly to GP
export PORT_USER="-p 5432"
# to connect through pgbouncer
#export PORT_USER="-p 6543 -U dsbench"

# benchmark options
export GEN_DATA_SCALE="1"
export MULTI_USER_COUNT="2"

# step options
# step 00_compile_tpcds
export RUN_COMPILE_TPCDS="true"

# step 01_gen_data
# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# the queries need to be regenerated with the new role
# change BENCH_ROLE and set RUN_GEN_DATA to true and GEN_NEW_DATA to false
# GEN_NEW_DATA only takes affect when RUN_GEN_DATA is true, and the default setting
# should true under normal circumstances
export RUN_GEN_DATA="true"
export GEN_NEW_DATA="true"

# step 02_init
export RUN_INIT="true"

# step 03_ddl
# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# change BENCH_ROLE and set RUN_DDL to true and DROP_EXISTING_TABLES to false
# DROP_EXISTING_TABLES only takes affect when RUN_DDL is true, and the default setting
# should true under normal circumstances
export RUN_DDL="true"
export DROP_EXISTING_TABLES="true"

# step 04_load
export RUN_LOAD="true"

# step 05_sql
export RUN_SQL="true"

# step 06_single_user_reports
export RUN_SINGLE_USER_REPORTS="true"

# step 07_multi_user
export RUN_QGEN="true"
export RUN_MULTI_USER="true"

# step 08_multi_user_reports
export RUN_MULTI_USER_REPORTS="true"

# step 09_score
export RUN_SCORE="true"

# misc options
export SINGLE_USER_ITERATIONS="1"
export EXPLAIN_ANALYZE="false"
export RANDOM_DISTRIBUTION="false"

# Set gpfdist location where gpfdist will run p (primary) or m (mirror)
export GPFDIST_LOCATION="p"

export OSVERSION=$(uname)
export MASTER_HOST=$(hostname -s)
export LD_PRELOAD=/lib64/libz.so.1 ps
