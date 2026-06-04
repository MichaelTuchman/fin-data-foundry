CREATE OR REPLACE VIEW vw_transactions_canonical_long AS
WITH row_layouts AS (
    SELECT DISTINCT
        r.source_system,
        r.account_id,
        r.account_label,
        r.account_type,
        r.institution,
        r.source_path,
        r.file_name,
        r.file_start_yyyymm,
        r.file_end_yyyymm,
        r.source_row_number,
        l.layout_id
    FROM vw_raw_csv_file_context r
    INNER JOIN metadata_layouts l
      ON r.source_system = l.source_system
     AND CAST(date_parse(concat(r.file_start_yyyymm, '01'), '%Y%m%d') AS date) >= CAST(l.effective_start_dt AS date)
     AND CAST(date_parse(concat(r.file_start_yyyymm, '01'), '%Y%m%d') AS date) < COALESCE(CAST(NULLIF(l.effective_end_dt, '') AS date), DATE '9999-12-31')
),
raw_long AS (
    SELECT
        r.source_system,
        r.account_id,
        r.account_label,
        r.account_type,
        r.institution,
        r.source_path,
        r.file_name,
        r.file_start_yyyymm,
        r.file_end_yyyymm,
        r.source_row_number,
        u.column_position,
        u.raw_value
    FROM vw_raw_csv_file_context r
    CROSS JOIN UNNEST(
        ARRAY[1,2,3,4,5,6,7,8,9,10],
        ARRAY[r.col01,r.col02,r.col03,r.col04,r.col05,r.col06,r.col07,r.col08,r.col09,r.col10]
    ) AS u(column_position, raw_value)
),
mapped AS (
    SELECT
        rl.source_system,
        rl.account_id,
        rl.account_label,
        rl.account_type,
        rl.institution,
        rl.source_path,
        rl.file_name,
        rl.file_start_yyyymm,
        rl.file_end_yyyymm,
        rl.source_row_number,
        rl.layout_id,
        r.column_position,
        lc.canonical_field,
        lc.expected_pattern,
        lower(trim(BOTH FROM lc.required)) = 'true' AS required,
        r.raw_value
    FROM row_layouts rl
    INNER JOIN raw_long r
      ON rl.source_system = r.source_system
     AND rl.account_id = r.account_id
     AND rl.source_path = r.source_path
     AND rl.source_row_number = r.source_row_number
    INNER JOIN metadata_layout_cols lc
      ON rl.source_system = lc.source_system
     AND rl.layout_id = lc.layout_id
     AND r.column_position = lc.column_position
),
valid_source_rows AS (
    SELECT
        source_system,
        account_id,
        source_path,
        source_row_number,
        layout_id
    FROM mapped
    GROUP BY
        source_system,
        account_id,
        source_path,
        source_row_number,
        layout_id
    HAVING SUM(
        CASE
            WHEN required = true
             AND (raw_value IS NULL OR regexp_like(raw_value, expected_pattern) = false)
            THEN 1
            ELSE 0
        END
    ) = 0
)
SELECT
    m.source_system,
    m.account_id,
    m.account_label,
    m.account_type,
    m.institution,
    m.source_path,
    m.file_name,
    m.file_start_yyyymm,
    m.file_end_yyyymm,
    m.source_row_number,
    m.layout_id,
    m.column_position,
    m.canonical_field,
    m.expected_pattern,
    m.required,
    m.raw_value
FROM mapped m
INNER JOIN valid_source_rows v
  ON m.source_system = v.source_system
 AND m.account_id = v.account_id
 AND m.source_path = v.source_path
 AND m.source_row_number = v.source_row_number
 AND m.layout_id = v.layout_id;

