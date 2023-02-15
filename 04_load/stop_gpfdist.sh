#!/bin/bash
set -e

for i in $(pgrep gpfdist); do
  echo "killing ${i}"
  kill "${i}"
done
