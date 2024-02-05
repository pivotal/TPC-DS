#!/bin/bash
set -e

VARS_FILE="tpcds_variables.sh"
FUNCTIONS_FILE="functions.sh"

# shellcheck source=tpcds_variables.sh
source ./${VARS_FILE}

# shellcheck source=functions.sh
source ./${FUNCTIONS_FILE}
source_bashrc

TPC_DS_DIR=$(get_pwd "${BASH_SOURCE[0]}")
export TPC_DS_DIR

# Check that pertinent variables are set in the variable file.
check_variables
print_header

# run the benchmark
./rollout.sh
