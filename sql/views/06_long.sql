CREATE OR REPLACE VIEW canon_long AS
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
        nullif(trim(u.raw_value), '') AS raw_value
    FROM layout_match lm
    CROSS JOIN UNNEST(
        ARRAY[1,2,3,4,5,6,7,8,9,10],
        ARRAY[lm.col01,lm.col02,lm.col03,lm.col04,lm.col05,lm.col06,lm.col07,lm.col08,lm.col09,lm.col10]
    ) AS u(column_position, raw_value)
), typed_long AS (
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
        lower(nullif(trim(mlc.validation_type), '')) AS validation_type,
        nullif(trim(mlc.validation_rule), '') AS validation_rule,
        mlc.required,
        lr.raw_value,
        CASE
            WHEN lower(nullif(trim(mlc.validation_type), '')) = 'date_format'
                THEN try_cast(try(date_parse(lr.raw_value, nullif(trim(mlc.validation_rule), ''))) AS date)
            ELSE NULL
        END AS parsed_date_value,
        CASE
            WHEN lower(mlc.canonical_field) = 'amount'
                THEN try_cast(regexp_replace(regexp_replace(lr.raw_value, '[$,]', ''), '^[(](.*)[)]$', '-$1') AS decimal(18,2))
            ELSE NULL
        END AS parsed_amount_value
    FROM long_raw lr
    JOIN metadata_layout_cols mlc
        ON lr.source_system = mlc.source_system
       AND lr.account_id = mlc.account_id
       AND lr.layout_id = mlc.layout_id
       AND lr.column_position = mlc.column_position
), validated_long AS (
    SELECT
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial,
        column_position,
        canonical_field,
        validation_type,
        validation_rule,
        required,
        raw_value,
        parsed_date_value,
        parsed_amount_value,
        CASE
            WHEN raw_value IS NULL AND required = false THEN true
            WHEN raw_value IS NULL AND required = true THEN false
            WHEN validation_type = 'text' THEN true
            WHEN validation_type = 'regex' AND validation_rule IS NOT NULL THEN regexp_like(raw_value, validation_rule)
            WHEN validation_type = 'date_format' THEN parsed_date_value IS NOT NULL
            ELSE false
        END AS validation_passed
    FROM typed_long
)
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,
    column_position,
    canonical_field,
    validation_type,
    validation_rule,
    required,
    raw_value,
    parsed_date_value,
    parsed_amount_value,
    validation_passed,
    validation_rule AS expected_pattern,
    validation_passed AS row_pattern_passed,
    CASE
        WHEN derived_row_serial = 1
         AND count_if(lower(canonical_field) = lower(raw_value)) OVER (
             PARTITION BY source_file_path, derived_row_serial
         ) > 0 THEN 'header'
        ELSE 'data'
    END AS row_classification
FROM validated_long;
