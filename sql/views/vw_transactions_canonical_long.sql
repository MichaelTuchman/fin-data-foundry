-- Input:
--     vw_raw_transactions_long
--     metadata_layouts
--     metadata_layout_cols
-- 
-- Output:
--     canonical_field
--     raw_value
CREATE OR REPLACE VIEW vw_transactions_canonical_long AS

WITH row_layouts AS (
    SELECT DISTINCT
        r.source_system,
        r.account_id,
        r.source_path,
        r.file_name,
        r.file_start_yyyymm,
        r.file_end_yyyymm,
        r.source_row_number,
        l.layout_id
    FROM vw_raw_transactions_long r
    INNER JOIN metadata_layouts l
      ON r.source_system = l.source_system
     AND CAST(date_parse(r.file_start_yyyymm || '01', '%Y%m%d') AS date)
         >= CAST(l.effective_start_dt AS date)
     AND CAST(date_parse(r.file_start_yyyymm || '01', '%Y%m%d') AS date)
         < COALESCE(
               CAST(NULLIF(l.effective_end_dt, '') AS date),
               DATE '9999-12-31'
           )
),

mapped AS (
    SELECT
        rl.source_system,
        rl.account_id,
        rl.source_path,
        rl.file_name,
        rl.file_start_yyyymm,
        rl.file_end_yyyymm,
        rl.source_row_number,
        rl.layout_id,

        r.column_position,
        lc.canonical_field,
        lc.expected_pattern,
        lc.required,
        r.raw_value
    FROM row_layouts rl
    INNER JOIN vw_raw_transactions_long r
      ON rl.source_system = r.source_system
     AND rl.account_id = r.account_id
     AND rl.source_path = r.source_path
     AND rl.source_row_number = r.source_row_number
    INNER JOIN metadata_layout_cols lc
      ON rl.source_system = lc.source_system
     AND rl.layout_id = lc.layout_id
     AND r.column_position = lc.column_position
)

SELECT *
FROM mapped;

