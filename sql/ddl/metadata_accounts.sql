CREATE EXTERNAL TABLE `metadata_accounts`(
  `source_system` string COMMENT 'from deserializer', 
  `account_id` string COMMENT 'from deserializer', 
  `account_label` string COMMENT 'from deserializer', 
  `account_type` string COMMENT 'from deserializer', 
  `institution` string COMMENT 'from deserializer', 
  `currency` string COMMENT 'from deserializer',
  `debit_sign_convention` string COMMENT 'from deserializer')
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
  's3://mftfinances/metadata/accounts'
TBLPROPERTIES (
  'skip.header.line.count'='1', 
  'transient_lastDdlTime'='1781475063')