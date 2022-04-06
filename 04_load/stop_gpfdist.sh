#!/bin/bash
set -e

# shellcheck disable=SC2009 #consider using pgrep
for i in $(ps -ef | grep gpfdist |  grep -v grep | grep -v stop_gpfdist | awk -F ' ' '{print $2}'); do
        echo "killing $i"
        kill "$i"
done
