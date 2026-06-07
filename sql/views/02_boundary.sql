CREATE OR REPLACE VIEW raw_boundary AS
SELECT
    "$path" AS source_file_path,
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
FROM raw_csv
