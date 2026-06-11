CREATE OR REPLACE VIEW debug_lens AS
SELECT
    cl.source_file_path,
    cl.source_file_name,
    cl.source_system,
    cl.account_id,
    cl.file_start_dt,
    cl.file_end_dt,
    cl.layout_id,
    cl.derived_row_serial,
    cl.column_position,
    cl.canonical_field,
    cl.validation_type,
    cl.validation_rule,
    cl.required,
    cl.raw_value,
    cl.parsed_date_value,
    cl.parsed_amount_value,
    cl.validation_passed,
    cl.row_classification,
    cw.transaction_date,
    cw.transaction_dt,
    cw.post_date,
    cw.post_dt,
    cw.description,
    cw.amount,
    cw.amount_d
FROM canon_long cl
LEFT JOIN canon_wide cw
    ON cl.source_file_path = cw.source_file_path
   AND cl.derived_row_serial = cw.derived_row_serial;
