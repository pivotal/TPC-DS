#!/bin/bash
set -e

function log_time() {
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

# runs on segment host; we don't inherit the functions
PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

GEN_DATA_SCALE=${1}
CHILD=${2}
PARALLEL=${3}
GEN_DATA_PATH=${4}
RNGSEED=${5}
SINGLE_SEGMENT="0"
DATA_DIRECTORY="${GEN_DATA_PATH}"

log_time "GEN_DATA_SCALE: ${GEN_DATA_SCALE}"
log_time "CHILD: ${CHILD}"
log_time "PARALLEL: ${PARALLEL}"
log_time "GEN_DATA_PATH: ${GEN_DATA_PATH}"

if [[ ! -d "${DATA_DIRECTORY}" && ! -L "${DATA_DIRECTORY}" ]]; then
  log_time "mkdir ${DATA_DIRECTORY}"
  mkdir "${DATA_DIRECTORY}"
fi

rm -f "${DATA_DIRECTORY}"/*

#for single nodes, you might only have a single segment but dsdgen requires at least 2
if [ "${PARALLEL}" -eq "1" ]; then
  PARALLEL="2"
  SINGLE_SEGMENT="1"
fi

cd "${PWD}"
log_time "${PWD}/dsdgen -scale ${GEN_DATA_SCALE} -dir ${DATA_DIRECTORY} -parallel ${PARALLEL} -child ${CHILD} -rngseed ${RNGSEED} -terminate n"
"${PWD}/dsdgen" -scale "${GEN_DATA_SCALE}" -dir "${DATA_DIRECTORY}" -parallel "${PARALLEL}" -child "${CHILD}" -rngseed "${RNGSEED}" -terminate n

# make sure there is a file in each directory so that gpfdist doesn't throw an error
declare -a tables=("call_center" "catalog_page" "catalog_returns" "catalog_sales" "customer" "customer_address" "customer_demographics" "date_dim" "household_demographics" "income_band" "inventory" "item" "promotion" "reason" "ship_mode" "store" "store_returns" "store_sales" "time_dim" "warehouse" "web_page" "web_returns" "web_sales" "web_site")

for i in "${tables[@]}"; do
  filename="${DATA_DIRECTORY}/${i}_${CHILD}_${PARALLEL}.dat"
  log_time "${filename}"
  if [ ! -f "${filename}" ]; then
    touch "${filename}"
  fi
done

#for single nodes, you might only have a single segment but dsdgen requires at least 2
if [ "$SINGLE_SEGMENT" -eq "1" ]; then
  CHILD="2"
  #build the second list of files
  log_time "${PWD}/dsdgen -scale ${GEN_DATA_SCALE} -dir ${DATA_DIRECTORY} -parallel ${PARALLEL} -child ${CHILD} -rngseed ${RNGSEED} -terminate n"
  "${PWD}"/dsdgen -scale "${GEN_DATA_SCALE}" -dir "${DATA_DIRECTORY}" -parallel "${PARALLEL}" -child "${CHILD}" -rngseed "${RNGSEED}" -terminate n

  # make sure there is a file in each directory so that gpfdist doesn't throw an error
  declare -a tables=("call_center" "catalog_page" "catalog_returns" "catalog_sales" "customer" "customer_address" "customer_demographics" "date_dim" "household_demographics" "income_band" "inventory" "item" "promotion" "reason" "ship_mode" "store" "store_returns" "store_sales" "time_dim" "warehouse" "web_page" "web_returns" "web_sales" "web_site")

  for i in "${tables[@]}"; do
    filename="${DATA_DIRECTORY}/${i}_${CHILD}_${PARALLEL}.dat"
    log_time "${filename}"
    if [ ! -f "${filename}" ]; then
      touch "${filename}"
    fi
  done
fi
