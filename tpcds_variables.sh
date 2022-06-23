# shellcheck disable=SC2148
# environment options
export ADMIN_USER="gpadmin"
export BENCH_ROLE="dsbench"

# benchmark options
export GEN_DATA_SCALE="1"
export MULTI_USER_COUNT="2"

# step options
export RUN_COMPILE_TPCDS="true"

# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# the queries need to be regenerated with the new role
# change BENCH_ROLE and set RUN_GEN_DATA to true and GEN_NEW_DATA to false
# GEN_NEW_DATA only takes affect when RUN_GEN_DATA is true, and the default setting
# should true under normal circumstances
export RUN_GEN_DATA="true"
export GEN_NEW_DATA="true"

export RUN_INIT="true"

# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# change BENCH_ROLE and set RUN_DDL to true and DROP_EXISTING_TABLES to false
# DROP_EXISTING_TABLES only takes affect when RUN_DDL is true, and the default setting
# should true under normal circumstances
export RUN_DDL="true"
export DROP_EXISTING_TABLES="true"

export RUN_LOAD="true"
export RUN_SQL="true"
export RUN_SINGLE_USER_REPORTS="true"

export RUN_QGEN="true"
export RUN_MULTI_USER="true"
export RUN_MULTI_USER_REPORTS="true"
export RUN_SCORE="true"

# misc options
export SINGLE_USER_ITERATIONS="1"
export EXPLAIN_ANALYZE="false"
export RANDOM_DISTRIBUTION="false"

# Set gpfdist location where gpfdist will run p (primary) or m (mirror)
export GPFDIST_LOCATION="p"

export OSVERSION=$(uname)
export ADMIN_USER=$(whoami)
export ADMIN_HOME=$(eval echo ${HOME}/${ADMIN_USER})
export MASTER_HOST=$(hostname -s)
export LD_PRELOAD=/lib64/libz.so.1 ps
