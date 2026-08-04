CREATE OR REPLACE VIEW "canon_long" AS
WITH raw_long AS (
    SELECT
        lm.source_file_path,
        lm.source_file_name,
        lm.source_system,
        lm.account_id,
        lm.file_start_dt,
        lm.file_end_dt,
        lm.layout_id,
        lm.derived_row_serial,
        CAST(u.column_pair[1] AS integer) AS column_position,
        u.column_pair[2] AS raw_value
    FROM finances.layout_match lm
    CROSS JOIN UNNEST(ARRAY[
        ARRAY['1', lm.col01],
        ARRAY['2', lm.col02],
        ARRAY['3', lm.col03],
        ARRAY['4', lm.col04],
        ARRAY['5', lm.col05],
        ARRAY['6', lm.col06],
        ARRAY['7', lm.col07],
        ARRAY['8', lm.col08],
        ARRAY['9', lm.col09],
        ARRAY['10', lm.col10]
    ]) u (column_pair)
),
joined AS (
    SELECT
        r.source_file_path,
        r.source_file_name,
        r.source_system,
        r.account_id,
        r.file_start_dt,
        r.file_end_dt,
        r.layout_id,
        r.derived_row_serial,
        r.column_position,
        trim(BOTH FROM c.canonical_field) AS canonical_field,
        lower(trim(BOTH FROM c.validation_type)) AS validation_type,
        trim(BOTH FROM c.validation_rule) AS validation_rule,
        lower(trim(BOTH FROM c.required)) AS required,
        r.raw_value
    FROM raw_long r
    INNER JOIN finances.metadata_layout_cols c
        ON r.source_system = c.source_system
       AND r.account_id = c.account_id
       AND r.layout_id = c.layout_id
       AND r.column_position = TRY_CAST(c.column_position AS integer)
),
normalized AS (
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
        CASE
            WHEN raw_value IS NULL OR trim(BOTH FROM raw_value) = '' THEN NULL
            WHEN regexp_like(trim(BOTH FROM raw_value), '^[(].*[)]$')
                THEN concat(
                    '-',
                    regexp_replace(
                        regexp_replace(trim(BOTH FROM raw_value), '[^0-9.,-]', ''),
                        ',',
                        ''
                    )
                )
            ELSE regexp_replace(
                regexp_replace(trim(BOTH FROM raw_value), '[^0-9.,-]', ''),
                ',',
                ''
            )
        END AS normalized_money_value
    FROM joined
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
    CASE
        WHEN raw_value IS NULL OR trim(BOTH FROM raw_value) = ''
            THEN NOT (required = 'true')

        WHEN validation_type IS NULL OR validation_type = ''
            THEN true

        WHEN validation_type = 'text'
            THEN true

        WHEN validation_type = 'regex'
            THEN regexp_like(trim(BOTH FROM raw_value), validation_rule)

        WHEN validation_type = 'money'
            THEN TRY_CAST(normalized_money_value AS decimal(18, 2)) IS NOT NULL

        WHEN validation_type = 'date_format'
             AND lower(validation_rule) = 'iso_8601'
            THEN TRY_CAST(trim(BOTH FROM raw_value) AS date) IS NOT NULL

        WHEN validation_type = 'date_format'
             AND lower(validation_rule) = 'mdy_slash'
            THEN TRY(date_parse(trim(BOTH FROM raw_value), '%m/%d/%Y')) IS NOT NULL

        WHEN validation_type = 'date_format'
            THEN TRY(date_parse(trim(BOTH FROM raw_value), validation_rule)) IS NOT NULL

        ELSE false
    END AS validation_passed
FROM normalized;
