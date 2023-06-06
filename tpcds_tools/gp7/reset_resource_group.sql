alter resource group default_group set CONCURRENCY 20;
alter resource group default_group set CPU_HARD_QUOTA_LIMIT 45;
alter resource group default_group set MEMORY_LIMIT 3000;

alter resource group admin_group set CONCURRENCY 10;
alter resource group admin_group set MEMORY_LIMIT -1;
SELECT * FROM gp_toolkit.gp_resgroup_config;
