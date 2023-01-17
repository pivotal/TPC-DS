#!/usr/bin/env bash

gpconfig -s gp_interconnect_queue_depth
gpconfig -s gp_interconnect_snd_queue_depth

gpconfig -s shared_buffers

gpconfig -s gp_enable_query_metrics

gpconfig -s gp_resource_manager

gpconfig -s gp_resource_group_bypass
gpconfig -s gp_resource_group_queuing_timeout

gpconfig -s gp_resource_group_cpu_ceiling_enforcement
gpconfig -s gp_resource_group_cpu_limit
gpconfig -s gp_resource_group_cpu_priority

gpconfig -s gp_resource_group_memory_limit
gpconfig -s gp_resgroup_memory_policy
gpconfig -s gp_workfile_compression

gpconfig -s memory_spill_ratio
gpconfig -s max_statement_mem
gpconfig -s statement_mem

gpconfig -s gp_dispatch_keepalives_idle
gpconfig -s gp_dispatch_keepalives_interval
gpconfig -s gp_dispatch_keepalives_count

gpconfig -s runaway_detector_activation_percent
gpconfig -s optimizer_enable_associativity

gpconfig -s gp_vmem_protect_limit
gpconfig -s gp_resqueue_memory_policy
gpconfig -s gp_resqueue_priority
gpconfig -s gp_resqueue_priority_cpucores_per_segment
gpconfig -s gp_resqueue_priority_sweeper_interval

psql -c "SELECT * FROM gp_toolkit.gp_resgroup_config order by groupid" template1
