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
        amount_d,
        check_number,
        status
    FROM trans_analy
),
purchase_authorized_removed AS (
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
        source_description,
        regexp_replace(
            description,
            '\bPURCHASE AUTHORIZED ON +[0-9]{1,2}/[0-9]{1,2} +',
            ''
        ) AS description,
        amount,
        amount_d,
        check_number,
        status
    FROM whitespace_normalized
),
recurring_payment_removed AS (
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
        source_description,
        regexp_replace(
            description,
            '\bRECURRING PAYMENT AUTHORIZED ON +[0-9]{1,2}/[0-9]{1,2} +',
            ''
        ) AS description,
        amount,
        amount_d,
        check_number,
        status
    FROM purchase_authorized_removed
),
legal_suffix_spaced AS (
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
        source_description,
        regexp_replace(
            description,
            '\b(LLC|INC|CORP|LTD|LP|LLP|PLLC|PC)([A-Z])',
            '$1 $2'
        ) AS description,
        amount,
        amount_d,
        check_number,
        status
    FROM recurring_payment_removed
),
punctuation_spaced AS (
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
        source_description,
        regexp_replace(
            description,
            '([!?,.;:])([A-Za-z])',
            '$1 $2'
        ) AS description,
        amount,
        amount_d,
        check_number,
        status
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
    derived_row_serial,
    transaction_date,
    transaction_dt,
    source_description,
    trim(
        regexp_replace(
            description,
            ' {2,}',
            ' '
        )
    ) AS description,
    amount,
    amount_d,
    check_number,
    status
FROM punctuation_spaced;