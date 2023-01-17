#!/usr/bin/env bash

gpconfig -c gp_resource_manager -v group

gpconfig -c gp_resource_group_memory_limit -v 0.9
gpconfig -c gp_resgroup_memory_policy -v auto
gpconfig -c gp_workfile_compression -v off

gpconfig -c runaway_detector_activation_percent -v 100
gpconfig -c optimizer_enable_associativity -v on

gpconfig -c gp_interconnect_queue_depth -v 16
gpconfig -c gp_interconnect_snd_queue_depth -v 16

# the following for mirrorless configuration only
# gpconfig -c gp_dispatch_keepalives_idle -v 20
# gpconfig -c gp_dispatch_keepalives_interval -v 20
# gpconfig -c gp_dispatch_keepalives_count -v 44

psql -f set_resource_group.sql template1
