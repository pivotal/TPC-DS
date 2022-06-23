#!/bin/bash

## getLogResults.sh
## Parameter ${1} is the tpcds log file from the run
## You will need to fill in columns A-K in the GPV TPC-DS.xlsx spreadsheet
## Paste the output from the command into column 'L', and use the spreadsheet's feature to split the text into columns with the ';' separator
tail -22 ${1} > /tmp/$$.txt

load=$(grep "^Load" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
loadhrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
analyze=$(grep "^Analyze" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
analyzehrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
queries=$(grep "^1 User" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
queryhrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
concurrent=$(grep "^Concurrent" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
concurrenthrs="=INDIRECT(ADDRESS(ROW(),COLUMN()-1))/(60*60)"
q=$(grep "^Q (3" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
tpt=$(grep "^TPT (seconds)" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
ttt=$(grep "^TTT (seconds)" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
tld=$(grep "^TLD (seconds)" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
score=$(grep -m1 "^Score" /tmp/$$.txt | sed -e 's/^.*[[:blank:]]//')
scorepercore="=INDIRECT(\"Y\"&ROW())/INDIRECT(\"H\"&ROW())*100"
scorecomp="=INDIRECT(\"C\"&ROW())*INDIRECT(\"U\"&ROW())/(INDIRECT(\"V\"&ROW())+INDIRECT(\"W\"&ROW())+INDIRECT(\"X\"&ROW())-2)"
qphds="=INDIRECT(\"C\"&ROW())*INDIRECT(\"U\"&ROW())/GEOMEAN(INDIRECT(\"N\"&ROW())*0.01*INDIRECT(\"D\"&ROW()), INDIRECT(\"R\"&ROW())*INDIRECT(\"D\"&ROW()), 2*(INDIRECT(\"T\"&ROW())/INDIRECT(\"D\"&ROW())))/3"

printf "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n" "${load}" "${loadhrs}" "${analyze}" "${analyzehrs}" "${queries}" "${queryhrs}" "${concurrent}" "${concurrenthrs}" "${q}" "${tpt}" "${ttt}" "${tld}" "${score}" "${scorepercore}" "${scorecomp}" "${qphds}"

rm -f /tmp/$$.txt
