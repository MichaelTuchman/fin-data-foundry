CREATE EXTERNAL TABLE `metadata_layout_controls`(
  `source_system` string,
  `account_id` string,
  `layout_id` string,
  `layout_valid_from` string,
  `layout_valid_to` string,
  `amount_model` string)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  'quoteChar'='\"',
  'separatorChar'=',')
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://mftfinances/metadata/layout_controls'
TBLPROPERTIES (
  'skip.header.line.count'='1');
