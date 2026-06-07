CREATE OR REPLACE VIEW vw_raw_csv_boundary AS
SELECT
    r."$path" AS source_file_path,

    r.col01,
    r.col02,
    r.col03,
    r.col04,
    r.col05,
    r.col06,
    r.col07,
    r.col08,
    r.col09,
    r.col10
FROM raw_csv r


-- Resulting fields:
-- source_file_path
-- col01
-- col02
-- col03
-- col04
-- col05
-- col06
-- col07
-- col08
-- col09
-- col10
;
