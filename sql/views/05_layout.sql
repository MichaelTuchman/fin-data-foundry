CREATE OR REPLACE VIEW layout_match AS
SELECT
    f.source_file_path,
    f.source_file_name,
    f.source_system,
    f.account_id,
    f.file_start_dt,
    f.file_end_dt,
    l.layout_id,
    f.derived_row_serial,
    f.col01,
    f.col02,
    f.col03,
    f.col04,
    f.col05,
    f.col06,
    f.col07,
    f.col08,
    f.col09,
    f.col10
FROM file_context f
INNER JOIN metadata_layouts l
    ON f.source_system = l.source_system
   AND f.file_start_dt >= CAST(l.effective_start_dt AS date)
   AND f.file_start_dt <= CAST(l.effective_end_dt AS date)
