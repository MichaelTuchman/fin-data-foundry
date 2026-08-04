CREATE OR REPLACE VIEW trans_analy AS
SELECT
    cw.source_file_path,
    cw.source_file_name,
    cw.source_system,
    cw.account_id,
    ma.account_label,
    ma.account_type,
    ma.institution,
    cw.file_start_dt,
    cw.file_end_dt,
    cw.layout_id,
    cw.amount_model,
    cw.derived_row_serial,
    cw.transaction_date,
    CAST(
        COALESCE(
            TRY_CAST(cw.transaction_date AS date),
            TRY(date_parse(cw.transaction_date, '%m/%d/%Y'))
        ) AS date
    ) AS transaction_dt,
    cw.description,
    cw.amount,
    cw.amount_d_source,
    cw.debit_amount,
    cw.debit_amount_d,
    cw.credit_amount,
    cw.credit_amount_d,
    cw.amount_source_field,
    cw.amount_d,
    cw.check_number,
    cw.status
FROM canon_wide cw
LEFT JOIN metadata_accounts ma
    ON cw.source_system = ma.source_system
   AND cw.account_id = ma.account_id
WHERE cw.amount_d IS NOT NULL;
