-- 5. vw_transactions_analysis

CREATE OR REPLACE VIEW vw_transactions_analysis AS
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

    TRY_CAST(transaction_date AS DATE) AS transaction_date,
    description,
    TRY_CAST(regexp_replace(amount, '[,$]', '') AS DECIMAL(18,2)) AS amount,
    check_number

FROM vw_transactions_wide;
