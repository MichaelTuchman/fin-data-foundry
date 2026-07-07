CREATE OR REPLACE VIEW canon_wide AS
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,
    MAX(CASE WHEN canonical_field = 'transaction_date' THEN raw_value END) AS transaction_date,
    MAX(CASE WHEN canonical_field = 'description' THEN raw_value END) AS description,
    MAX(CASE WHEN canonical_field = 'amount' THEN raw_value END) AS amount,
    TRY_CAST(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    MAX(CASE WHEN canonical_field = 'amount' THEN raw_value END),
                    '[$,]',
                    ''
                ),
                '^\((.*)\)$',
                '-$1'
            ),
            '^$',
            NULL
        ) AS double
    ) AS amount_d,
    MAX(CASE WHEN canonical_field = 'check_number' THEN raw_value END) AS check_number,
    MAX(CASE WHEN canonical_field = 'status' THEN raw_value END) AS status
FROM canon_long
GROUP BY
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial
HAVING
    MAX(CASE WHEN canonical_field = 'transaction_date' THEN raw_value END) <> 'Date'
    AND MAX(CASE WHEN canonical_field = 'amount' THEN raw_value END) <> 'Amount';