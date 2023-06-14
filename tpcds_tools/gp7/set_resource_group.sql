alter resource group default_group set CONCURRENCY 5;
alter resource group default_group set CPU_HARD_QUOTA_LIMIT 90;
alter resource group default_group set MEMORY_LIMIT 25000;

alter resource group admin_group set CONCURRENCY 5;
alter resource group admin_group set CPU_HARD_QUOTA_LIMIT 90;
alter resource group admin_group set MEMORY_LIMIT 25000;

alter resource group system_group set CPU_HARD_QUOTA_LIMIT 90;
SELECT * FROM gp_toolkit.gp_resgroup_config;
