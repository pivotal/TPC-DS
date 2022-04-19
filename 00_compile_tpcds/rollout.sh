#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# shellcheck source=functions.sh
source "$PWD"/../functions.sh
source_bashrc

step='compile_tpcds'
init_log "$step"
start_log

make_tpc()
{
	#compile the tools
	cd "$PWD"/tools
	rm -f ./*.o
	make
	cd ..
}

log_binary_versions()
{
	# only below binaries have option to get version information
	# we need to update list if we have additinoal binary in future release
	echo "logging TPC-DS tools binary versions: log/tpcds_tools_version.txt"
	"$PWD"/tools/dsdgen -re | head -1 > "$PWD"/../log/tpcds_tools_version.txt
	"$PWD"/tools/dsqgen -re | head -1 >> "$PWD"/../log/tpcds_tools_version.txt
	"$PWD"/tools/distcomp HELP | head -1 >> "$PWD"/../log/tpcds_tools_version.txt
}

copy_tpc()
{
	cp "$PWD"/tools/dsqgen ../*_gen_data/
	cp "$PWD"/tools/dsqgen ../*_multi_user/
	cp "$PWD"/tools/tpcds.idx ../*_gen_data/
	cp "$PWD"/tools/tpcds.idx ../*_multi_user/

	#copy the compiled dsdgen program to the segment nodes
	for i in $(cat "$PWD"/../segment_hosts.txt); do
		echo "copy tpcds binaries to $i:$ADMIN_HOME"
		scp tools/dsdgen tools/tpcds.idx "${i}:${ADMIN_HOME}"/
	done
}

copy_queries()
{
	rm -rf "$PWD"/../*_gen_data/query_templates
	rm -rf "$PWD"/../*_multi_user/query_templates
	cp -R query_templates "$PWD"/../*_gen_data/
	cp -R query_templates "$PWD"/../*_multi_user/
}

make_tpc
log_binary_versions
create_hosts_file
copy_tpc
copy_queries
log

echo "Finished $step"
