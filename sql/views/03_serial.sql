CREATE OR REPLACE VIEW raw_serial AS
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
    ) AS derived_row_serial,
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
FROM raw_boundary

