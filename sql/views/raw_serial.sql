01 CREATE OR REPLACE VIEW raw_serial AS
02 SELECT
03     source_file_path,
04     row_number() OVER (
05         PARTITION BY source_file_path
06         ORDER BY
07             col01,
08             col02,
09             col03,
10             col04,
11             col05,
12             col06,
13             col07,
14             col08,
15             col09,
16             col10
17     ) AS raw_row_serial,
18     col01,
19     col02,
20     col03,
21     col04,
22     col05,
23     col06,
24     col07,
25     col08,
26     col09,
27     col10
28 FROM raw_boundary
