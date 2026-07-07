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
    cw.derived_row_serial,
    cw.transaction_date,
    TRY_CAST(date_parse(cw.transaction_date, '%m/%d/%Y') AS date) AS transaction_dt,
    cw.description,
    cw.amount,
    cw.amount_d AS amount_d_raw,
    cw.amount_d * (-1 * ma.debit_sign_convention) AS amount_d,
    cw.check_number,
    cw.status
FROM canon_wide cw
LEFT JOIN metadata_accounts ma
    ON cw.source_system = ma.source_system
   AND cw.account_id = ma.account_id;
