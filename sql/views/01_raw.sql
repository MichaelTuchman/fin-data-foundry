-- File: 01_raw.sql
-- Execution Order: 01
-- Object: raw_csv
--
-- Purpose:
-- Physical Athena external table over uploaded CSV files.
-- This table intentionally contains no business logic, layout logic,
-- type conversions, or file context parsing.
--
-- Depends On:
--   S3 raw data files
--
-- Produces:
--   Generic raw columns (col01-col10)
--
-- Resulting Fields:
--   col01
--   col02
--   col03
--   col04
--   col05
--   col06
--   col07
--   col08
--   col09
--   col10

CREATE EXTERNAL TABLE IF NOT EXISTS raw_csv (
    col01 STRING,
    col02 STRING,
    col03 STRING,
    col04 STRING,
    col05 STRING,
    col06 STRING,
    col07 STRING,
    col08 STRING,
    col09 STRING,
    col10 STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"'
)
STORED AS TEXTFILE
LOCATION 's3://mftfinances/raw/'
TBLPROPERTIES (
    'skip.header.line.count' = '0'
);

