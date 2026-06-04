CREATE OR REPLACE VIEW vw_transactions_wide AS
SELECT
    source_system,
    account_id,
    account_label,
    account_type,
    institution,
    source_path,
    file_name,
    file_start_yyyymm,
    file_end_yyyymm,
    source_row_number,
    layout_id,
    max(CASE WHEN canonical_field = 'transaction_date' THEN raw_value END) AS transaction_date,
    max(CASE WHEN canonical_field = 'description' THEN raw_value END) AS description,
    max(CASE WHEN canonical_field = 'amount' THEN raw_value END) AS amount,
    max(CASE WHEN canonical_field = 'check_number' THEN raw_value END) AS check_number
FROM vw_transactions_canonical_long
GROUP BY
    source_system,
    account_id,
    account_label,
    account_type,
    institution,
    source_path,
    file_name,
    file_start_yyyymm,
    file_end_yyyymm,
    source_row_number,
    layout_id;

