#!/bin/bash

## getLogResults.sh
## Parameter ${1} is the tpcds log file from the run
## You will need to fill in columns A-K in the GPV TPC-DS.xlsx spreadsheet
## Paste the output from the command into column 'L', and use the spreadsheet's feature to split the text into columns with the ';' separator
tail -22 "${1}" > /tmp/$$.txt

load=$(grep "^Load" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
loadhrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
analyze=$(grep "^Analyze" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
analyzehrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
queries=$(grep "^1 User" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
queryhrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
concurrent=$(grep "^Sum of Elap" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
concurrenthrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
q="=INDIRECT(ADDRESS(ROW(),COLUMN()-17))*99*3"
tpt=$(grep "^TPT (seconds)" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
ttt=$(grep "^TTT (seconds)" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
tld=$(grep "^TLD (seconds)" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
score=$(grep -m1 "^Score" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
scorepercore="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/INDIRECT(ADDRESS(ROW(),COLUMN()-18))*100"
scorecomp="=INDIRECT(ADDRESS(ROW(),COLUMN()-6))*INDIRECT(ADDRESS(ROW(),COLUMN()-24))/((INDIRECT(ADDRESS(ROW(),COLUMN()-5))+INDIRECT(ADDRESS(ROW(),COLUMN()-4))+INDIRECT(ADDRESS(ROW(),COLUMN()-3))))"
qphds=$(grep "^Score" /tmp/$$.txt | tail -1 | sed -e 's/^.*[[:blank:]]//')

printf "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n" "${load}" "${loadhrs}" "${analyze}" "${analyzehrs}" "${queries}" "${queryhrs}" "${concurrent}" "${concurrenthrs}" "${q}" "${tpt}" "${ttt}" "${tld}" "${score}" "${scorepercore}" "${scorecomp}" "${qphds}"

rm -f /tmp/$$.txt
