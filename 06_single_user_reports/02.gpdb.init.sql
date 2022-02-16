CREATE TABLE tpcds_reports.init
(id int, description varchar, tuples bigint, duration time, start_epoch_seconds bigint, end_epoch_seconds bigint)
DISTRIBUTED BY (id);
