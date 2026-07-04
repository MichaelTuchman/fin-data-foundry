CREATE OR REPLACE VIEW trans_cleaned AS
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    account_label,
    account_type,
    institution,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,
    transaction_date,
    transaction_dt,
    description AS source_description,
    TRIM(
        regexp_replace(
            regexp_replace(
                regexp_replace(description, '[\r\n\t]+', ' '),
                ' +',
                ' '
            ),
            '(^ +| +$)',
            ''
        )
    ) AS description,
    amount,
    amount_d,
    check_number,
    status
FROM trans_analy
