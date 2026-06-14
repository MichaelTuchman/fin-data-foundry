CREATE OR REPLACE VIEW finances.canon_wide AS
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,

    MAX(CASE WHEN lower(canonical_field) = 'transaction_date'
        THEN raw_value END) AS transaction_date,

    MAX(CASE WHEN lower(canonical_field) = 'description'
        THEN raw_value END) AS description,

    MAX(CASE WHEN lower(canonical_field) = 'amount'
        THEN raw_value END) AS amount,

    MAX(CASE WHEN lower(canonical_field) = 'check_number'
        THEN raw_value END) AS check_number,

    MAX(CASE WHEN lower(canonical_field) = 'status'
        THEN raw_value END) AS status

FROM finances.canon_long
WHERE validation_passed
GROUP BY
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial

