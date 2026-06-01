CREATE EXTERNAL TABLE metadata_layout_cols (
    source_system      STRING,
    layout_id          STRING,
    column_position    INT,
    canonical_field    STRING,
    expected_pattern   STRING,
    required           BOOLEAN
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"'
)
STORED AS TEXTFILE
LOCATION 's3://mftfinances/metadata/layout_cols/'
TBLPROPERTIES (
    'skip.header.line.count' = '1'
);

