CREATE TABLE IF NOT EXISTS tpcds_variables(
id SERIAL,
variables TEXT
);

CREATE TABLE IF NOT EXISTS infra_infos(
id SERIAL,
infra_name VARCHAR(500),
datastore_type VARCHAR(160)
);

CREATE TABLE IF NOT EXISTS greenplum_infos(
id SERIAL,
cluster_size INT,
deployment_type VARCHAR(160),
gucs TEXT,
compile_config TEXT,
role VARCHAR(160),
memory_manager VARCHAR(160)
);

CREATE TABLE IF NOT EXISTS score_v131(
id SERIAL,
sq INT,
q INT,
tld DOUBLE PRECISION,
tpt DOUBLE PRECISION,
ttt DOUBLE PRECISION,
score INT
);

CREATE TABLE IF NOT EXISTS score_v220(
id SERIAL,
sq INT,
q INT,
tld DOUBLE PRECISION,
tpt DOUBLE PRECISION,
ttt DOUBLE PRECISION,
score INT
);

CREATE TABLE IF NOT EXISTS single_users(
id SERIAL,
time TEXT
/* query_id SERIAL, */
/* session_id INT, */
/* time_elapsed INT, */
);

CREATE TABLE IF NOT EXISTS system_configs(
id SERIAL,
cpu INT,
cpu_model VARCHAR(160),
data_disk_gb INT,
kernel VARCHAR(160) ,
memory_gb INT,
rhp VARCHAR(160) ,
root_disk_gb INT,
thp VARCHAR(160)
);

CREATE TABLE IF NOT EXISTS gpds_benches(
id SERIAL,
analyze_sec INT,
description TEXT,
story_id TEXT,
notes TEXT,
greenplum_info_refer SERIAL,
infra_info_refer SERIAL,
load_sec INT,
num_of_streams INT,
scale_factor INT,
score_v131_refer SERIAL,
score_v220_refer SERIAL,
single_user_refer SERIAL,
single_user_sec INT,
sum_of_elapsetime_all_con_query_sec INT,
system_config_refer SERIAL,
throughput_test_elapsed_time_sec INT,
tpcds_variable_refer SERIAL
);
