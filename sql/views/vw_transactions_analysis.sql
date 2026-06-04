CREATE OR REPLACE VIEW vw_transactions_analysis AS
WITH typed AS (
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
        try_cast(transaction_date AS date) AS transaction_date,
        description,
        try_cast(regexp_replace(amount, '[,$]', '') AS decimal(18,2)) AS amount_reported,
        check_number
    FROM vw_transactions_wide
)
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
    transaction_date,
    description,
    amount_reported,
    CASE
        WHEN account_type = 'liability' THEN -1 * amount_reported
        ELSE amount_reported
    END AS amount,
    check_number
FROM typed;
