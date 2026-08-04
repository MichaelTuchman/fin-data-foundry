CREATE EXTERNAL TABLE `metadata_layout_cols`(
  `source_system` string COMMENT 'from deserializer', 
  `account_id` string COMMENT 'from deserializer', 
  `layout_id` string COMMENT 'from deserializer', 
  `column_position` string COMMENT 'from deserializer', 
  `canonical_field` string COMMENT 'from deserializer', 
  `validation_type` string COMMENT 'from deserializer', 
  `validation_rule` string COMMENT 'from deserializer', 
  `required` string COMMENT 'from deserializer')
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
  's3://your_bucket_root/metadata/layout_cols'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1781147701')

