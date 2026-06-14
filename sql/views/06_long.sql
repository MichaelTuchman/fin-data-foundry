CREATE OR REPLACE VIEW finances.canon_long AS
WITH long_raw AS (
    SELECT
        lm.source_file_path,
        lm.source_file_name,
        lm.source_system,
        lm.account_id,
        lm.file_start_dt,
        lm.file_end_dt,
        lm.layout_id,
        lm.derived_row_serial,
        u.column_position,
        NULLIF(TRIM(u.raw_value), '') AS raw_value
    FROM finances.layout_match lm
    CROSS JOIN UNNEST(
        ARRAY[1,2,3,4,5,6,7,8,9,10],
        ARRAY[lm.col01,lm.col02,lm.col03,lm.col04,lm.col05,lm.col06,lm.col07,lm.col08,lm.col09,lm.col10]
    ) AS u(column_position, raw_value)
)
SELECT
    lr.source_file_path,
    lr.source_file_name,
    lr.source_system,
    lr.account_id,
    lr.file_start_dt,
    lr.file_end_dt,
    lr.layout_id,
    lr.derived_row_serial,
    lr.column_position,
    mlc.canonical_field,
    LOWER(NULLIF(TRIM(mlc.validation_type), '')) AS validation_type,
    NULLIF(TRIM(mlc.validation_rule), '') AS validation_rule,
    LOWER(NULLIF(TRIM(mlc.required), '')) IN ('true','t','yes','y','1') AS required,
    lr.raw_value,
    CASE
        WHEN lr.raw_value IS NULL
          THEN NOT (LOWER(NULLIF(TRIM(mlc.required), '')) IN ('true','t','yes','y','1'))
        WHEN LOWER(NULLIF(TRIM(mlc.validation_type), '')) = 'text'
          THEN true
        WHEN LOWER(NULLIF(TRIM(mlc.validation_type), '')) = 'regex'
          THEN regexp_like(lr.raw_value, NULLIF(TRIM(mlc.validation_rule), ''))
        WHEN LOWER(NULLIF(TRIM(mlc.validation_type), '')) = 'date_format'
          THEN TRY_CAST(TRY(date_parse(lr.raw_value, NULLIF(TRIM(mlc.validation_rule), ''))) AS date) IS NOT NULL
        ELSE false
    END AS validation_passed
FROM long_raw lr
INNER JOIN finances.metadata_layout_cols mlc
    ON lr.source_system = mlc.source_system
   AND lr.account_id = mlc.account_id
   AND lr.layout_id = mlc.layout_id
   AND lr.column_position = TRY_CAST(mlc.column_position AS integer)

