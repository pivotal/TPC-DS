# environment options
export ADMIN_USER="gpadmin"
export BENCH_ROLE="gpadmin"

# benchmark options
export GEN_DATA_SCALE="1"
export MULTI_USER_COUNT="2"

# step options
export RUN_COMPILE_TPCDS="false"
export RUN_GEN_DATA="true"
export RUN_INIT="true"
export RUN_DDL="true"
export RUN_LOAD="true"
export RUN_SQL="true"
export RUN_SINGLE_USER_REPORTS="true"
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
export ADMIN_HOME=$(eval echo ~${ADMIN_USER})
export MASTER_HOST=$(hostname -s)
export LD_PRELOAD=/lib64/libz.so.1 ps
