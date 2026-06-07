CREATE OR REPLACE VIEW trans_analy AS
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,

    try_cast(transaction_date AS date) AS transaction_dt,
    description,
    try_cast(amount AS decimal(18, 2)) AS amount,
    check_number,
    status,
    row_pattern_passed
FROM canon_wide
