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
    amount_model,
    derived_row_serial,
    transaction_date,
    transaction_dt,
    source_description,
    description AS cleaned_description,
    CASE
        WHEN transaction_type = 'credit_card_payment' THEN
            trim(
                regexp_replace(
                    regexp_replace(
                        regexp_replace(
                            regexp_replace(description, '\bONLINE PAYMENT\b', ''),
                            '\bWEB PYMT\b',
                            ''
                        ),
                        '\bPAYMENT\b',
                        ''
                    ),
                    ' {2,}',
                    ' '
                )
            )
        ELSE description
    END AS description,
    amount,
    amount_d_source,
    debit_amount,
    debit_amount_d,
    credit_amount,
    credit_amount_d,
    amount_source_field,
    amount_d,
    check_number,
    status,
    transaction_type,
    transaction_subtype,
    matched_transaction_type_rule_id,
    matched_transaction_type_rule_priority
FROM trans_typed;
