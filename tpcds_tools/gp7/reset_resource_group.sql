alter resource group default_group set CONCURRENCY 20;
alter resource group default_group set CPU_HARD_QUOTA_LIMIT 20;
alter resource group default_group set CPU_SOFT_PRIORITY 100;
alter resource group default_group set MEMORY_LIMIT -1;
alter resource group default_group set MIN_COST 500;

alter resource group admin_group set CONCURRENCY 10;
alter resource group admin_group set CPU_HARD_QUOTA_LIMIT 10;
alter resource group admin_group set CPU_SOFT_PRIORITY 100;
alter resource group admin_group set MEMORY_LIMIT -1;
alter resource group admin_group set MIN_COST 500;

alter resource group system_group set CONCURRENCY 0;
alter resource group system_group set CPU_HARD_QUOTA_LIMIT 10;
alter resource group system_group set CPU_SOFT_PRIORITY 100;
alter resource group system_group set MEMORY_LIMIT -1;
alter resource group system_group set MIN_COST 500;

SELECT * FROM gp_toolkit.gp_resgroup_config;
