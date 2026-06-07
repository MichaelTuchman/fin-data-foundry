CREATE OR REPLACE VIEW vw_raw_csv_with_file_path AS
SELECT
    r."$path" AS source_file_path,
    r.source_line_number AS source_row_number,
    r.col01, r.col02, r.col03, r.col04, r.col05,
    r.col06, r.col07, r.col08, r.col09, r.col10
FROM raw_csv r;
