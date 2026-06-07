CREATE OR REPLACE VIEW vw_raw_csv_with_reshape_row AS
SELECT
    source_file_path,

    row_number() OVER (
        PARTITION BY source_file_path
        ORDER BY
            col01,
            col02,
            col03,
            col04,
            col05,
            col06,
            col07,
            col08,
            col09,
            col10
    ) AS reshape_row_number,

    col01,
    col02,
    col03,
    col04,
    col05,
    col06,
    col07,
    col08,
    col09,
    col10
FROM vw_raw_csv_boundary


-- Resulting fields:
-- source_file_path
-- reshape_row_number
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
