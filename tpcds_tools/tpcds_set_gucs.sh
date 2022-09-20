#Set gucs for TPC-DS
gpconfig -c gp_interconnect_queue_depth -v 16
gpconfig -c gp_interconnect_snd_queue_depth -v 16

gpconfig -c gp_resource_manager -v group
gpconfig -c gp_resource_group_memory_limit -v .9
gpconfig -c gp_resgroup_memory_policy -v auto

gpconfig -c runaway_detector_activation_percent -v 100
gpconfig -c optimizer_enable_associativity -v on
gpconfig -c optimizer_analyze_root_partition -v on
