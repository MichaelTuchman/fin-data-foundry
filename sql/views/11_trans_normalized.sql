CREATE OR REPLACE VIEW trans_normalized AS
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
    description_original,
    description AS description_cleaned,
    CASE
        WHEN transaction_type = 'credit_card_payment' THEN
            trim(
                regexp_replace(
                    regexp_replace(
                        regexp_replace(description, '\bONLINE PAYMENT\b', ''),
                        '\bWEB PYMT\b',
                        ''
                    ),
                    ' {2,}',
                    ' '
                )
            )
        ELSE description
    END AS description,
    amount,
    amount_d,
    check_number,
    status,
    transaction_type,
    transaction_subtype,
    transaction_type_rule_id
FROM trans_typed;
