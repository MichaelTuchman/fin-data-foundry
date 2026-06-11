CREATE OR REPLACE VIEW layout_match AS
SELECT
    fc.source_file_path,
    fc.source_file_name,
    fc.source_system,
    fc.account_id,
    fc.file_start_dt,
    fc.file_end_dt,
    ml.layout_id,
    fc.derived_row_serial,
    fc.col01,
    fc.col02,
    fc.col03,
    fc.col04,
    fc.col05,
    fc.col06,
    fc.col07,
    fc.col08,
    fc.col09,
    fc.col10
FROM file_context fc
JOIN metadata_layouts ml
    ON fc.source_system = ml.source_system
   AND fc.account_id = ml.account_id
   AND fc.file_start_dt >= try_cast(nullif(cast(ml.effective_start_dt AS varchar), '') AS date)
   AND fc.file_end_dt <= coalesce(
        try_cast(nullif(cast(ml.effective_end_dt AS varchar), '') AS date),
        current_date
   );
