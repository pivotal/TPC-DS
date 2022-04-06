#!/bin/bash

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$PWD"/../tpcds_variables.sh
source_bashrc

set -e

query_id=1
file_id=101

GEN_DATA_SCALE=${1}
BENCH_ROLE=${2}

if [ "$GEN_DATA_SCALE" == "" ] || [ "$BENCH_ROLE" == "" ]; then
	echo "Usage: generate_queries.sh scale rolename"
	echo "Example: ./generate_queries.sh 100 dsbench"
	echo "This creates queries for 100GB of data."
	exit 1
fi

rm -f "$PWD"/query_0.sql

echo "$PWD/dsqgen -input $PWD/query_templates/templates.lst -directory $PWD/query_templates -dialect pivotal -scale $GEN_DATA_SCALE -verbose y -output $PWD"
"$PWD"/dsqgen -input "$PWD"/query_templates/templates.lst -directory "$PWD"/query_templates -dialect pivotal -scale "$GEN_DATA_SCALE" -verbose y -output "$PWD"

rm -f "$PWD"/../05_sql/*."${BENCH_ROLE}".*.sql*

for p in $(seq 1 99); do
	q=$(printf %02d "$query_id")
	filename="$file_id.${BENCH_ROLE}.$q.sql"
	template_filename="query$p.tpl"
	start_position=""
	end_position=""
	for pos in $(grep -n "$template_filename" "$PWD"/query_0.sql | awk -F ':' '{print $1}'); do
		if [ "$start_position" == "" ]; then
			start_position="$pos"
		else
			end_position="$pos"
		fi
	done

	echo "Creating: $PWD/../05_sql/$filename"
	printf "set role %s;\n:EXPLAIN_ANALYZE\n" "${BENCH_ROLE}" > "$PWD"/../05_sql/"$filename"
	sed -n "$start_position","$end_position"p "$PWD"/query_0.sql >> "$PWD"/../05_sql/"$filename"
	query_id=$((query_id + 1))
	file_id=$((file_id + 1))
	echo "Completed: $PWD/../05_sql/$filename"
done

echo ""
echo "queries 114, 123, 124, and 139 have 2 queries in each file.  Need to add :EXPLAIN_ANALYZE to second query in these files"
echo ""
arr=("114.${BENCH_ROLE}.14.sql" "123.${BENCH_ROLE}.23.sql" "124.${BENCH_ROLE}.24.sql" "139.${BENCH_ROLE}.39.sql")

for z in "${arr[@]}"; do
	echo "$z"
	myfilename="$PWD"/../05_sql/"$z"
	echo "Modifying: $myfilename"
	pos=$(grep -n ";" "$myfilename" | awk -F ':' ' { if (NR > 1) print $1 }' | head -1)
	pos=$((pos + 1))
	echo "pos: $pos"
	sed -i ''"$pos"'i\'$'\n'':EXPLAIN_ANALYZE'$'\n' "$myfilename"
	echo "Modified: $myfilename"

done

echo "COMPLETE: dsqgen scale $GEN_DATA_SCALE"
