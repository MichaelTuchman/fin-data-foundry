CREATE EXTERNAL TABLE metadata_layouts (
    source_system       STRING,
    layout_id           STRING,
    effective_start_dt  STRING,
    effective_end_dt    STRING,
    header_rows         INT,
    skip_rows           INT
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"'
)
STORED AS TEXTFILE
LOCATION 's3://mftfinances/metadata/layouts/'
TBLPROPERTIES (
    'skip.header.line.count' = '1'
);

