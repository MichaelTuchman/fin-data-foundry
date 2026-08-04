CREATE OR REPLACE VIEW trans_cleaned AS
WITH whitespace_normalized AS (
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
        description AS source_description,
        trim(
            regexp_replace(
                regexp_replace(
                    description,
                    '[\r\n\t]+',
                    ' '
                ),
                ' {2,}',
                ' '
            )
        ) AS description,
        amount,
        amount_d_source,
        debit_amount,
        debit_amount_d,
        credit_amount,
        credit_amount_d,
        amount_source_field,
        amount_d,
        check_number,
        status
    FROM trans_analy
),
purchase_authorized_removed AS (
    SELECT
        *,
        regexp_replace(
            description,
            '\bPURCHASE AUTHORIZED ON +[0-9]{1,2}/[0-9]{1,2} +',
            ''
        ) AS next_description
    FROM whitespace_normalized
),
recurring_payment_removed AS (
    SELECT
        *,
        regexp_replace(
            next_description,
            '\bRECURRING PAYMENT AUTHORIZED ON +[0-9]{1,2}/[0-9]{1,2} +',
            ''
        ) AS next_description_2
    FROM purchase_authorized_removed
),
legal_suffix_spaced AS (
    SELECT
        *,
        regexp_replace(
            next_description_2,
            '\b(LLC|INC|CORP|LTD|LP|LLP|PLLC|PC)([A-Z])',
            '$1 $2'
        ) AS next_description_3
    FROM recurring_payment_removed
),
punctuation_spaced AS (
    SELECT
        *,
        regexp_replace(
            next_description_3,
            '([!?,.;:])([A-Za-z])',
            '$1 $2'
        ) AS next_description_4
    FROM legal_suffix_spaced
)
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
    trim(
        regexp_replace(
            next_description_4,
            ' {2,}',
            ' '
        )
    ) AS description,
    amount,
    amount_d_source,
    debit_amount,
    debit_amount_d,
    credit_amount,
    credit_amount_d,
    amount_source_field,
    amount_d,
    check_number,
    status
FROM punctuation_spaced;
