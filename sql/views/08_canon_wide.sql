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
    max(CASE WHEN canonical_field = 'transaction_date' THEN raw_value END) AS transaction_date,
    max(CASE WHEN canonical_field = 'description' THEN raw_value END) AS description,
    max(CASE WHEN canonical_field = 'amount' THEN raw_value END) AS amount,
    max(CASE WHEN canonical_field = 'check_number' THEN raw_value END) AS check_number,
    max(CASE WHEN canonical_field = 'status' THEN raw_value END) AS status,
    min(pattern_passed) AS row_pattern_passed
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
