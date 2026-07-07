CREATE EXTERNAL TABLE `metadata_layout_controls`(
  `source_system` string COMMENT 'from deserializer', 
  `account_id` string COMMENT 'from deserializer', 
  `layout_id` string COMMENT 'from deserializer', 
  `layout_valid_from` string COMMENT 'from deserializer', 
  `layout_valid_to` string COMMENT 'from deserializer')
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
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1781149447')
