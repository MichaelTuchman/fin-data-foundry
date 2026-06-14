CREATE OR REPLACE VIEW finances.trans_analy AS
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
    TRY_CAST(cw.transaction_date AS date) AS transaction_dt,
    cw.description,
    cw.amount,
    TRY_CAST(cw.amount AS decimal(18,2)) AS amount_d,
    cw.check_number,
    cw.status
FROM finances.canon_wide cw
LEFT JOIN finances.metadata_accounts ma
    ON cw.source_system = ma.source_system
   AND cw.account_id = ma.account_id
