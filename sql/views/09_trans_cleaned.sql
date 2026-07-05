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
    trim(
        regexp_replace(
            regexp_replace(
                regexp_replace(
                    regexp_replace(
                        regexp_replace(
                            regexp_replace(
                                description,
                                '[\r\n\t]+',
                                ' '
                            ),
                            '\bPURCHASE AUTHORIZED ON +[0-9]{1,2}/[0-9]{1,2} +',
                            ''
                        ),
                        '\bRECURRING PAYMENT AUTHORIZED ON +[0-9]{1,2}/[0-9]{1,2} +',
                        ''
                    ),
                    '\b(LLC|INC|CORP|LTD|LP|LLP|PLLC|PC)([A-Z])',
                    '$1 $2'
                ),
                '([!?,.;:])([A-Za-z])',
                '$1 $2'
            ),
            ' {2,}',
            ' '
        )
    ) AS description,
    amount,
    amount_d,
    check_number,
    status
FROM trans_analy;

