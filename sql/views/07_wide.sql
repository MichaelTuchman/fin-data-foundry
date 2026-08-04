CREATE OR REPLACE VIEW canon_wide AS
WITH wide AS (
    SELECT
        cl.source_file_path,
        cl.source_file_name,
        cl.source_system,
        cl.account_id,
        cl.file_start_dt,
        cl.file_end_dt,
        cl.layout_id,
        lower(trim(mlc.amount_model)) AS amount_model,
        cl.derived_row_serial,
        MAX(
            CASE
                WHEN cl.canonical_field = 'transaction_date'
                THEN cl.raw_value
            END
        ) AS transaction_date,
        MAX(
            CASE
                WHEN cl.canonical_field = 'description'
                THEN cl.raw_value
            END
        ) AS description,
        NULLIF(
            TRIM(
                MAX(
                    CASE
                        WHEN cl.canonical_field = 'amount'
                        THEN cl.raw_value
                    END
                )
            ),
            ''
        ) AS amount_value,
        NULLIF(
            TRIM(
                MAX(
                    CASE
                        WHEN cl.canonical_field = 'debit_amount'
                        THEN cl.raw_value
                    END
                )
            ),
            ''
        ) AS debit_amount_value,
        NULLIF(
            TRIM(
                MAX(
                    CASE
                        WHEN cl.canonical_field = 'credit_amount'
                        THEN cl.raw_value
                    END
                )
            ),
            ''
        ) AS credit_amount_value,
        MAX(
            CASE
                WHEN cl.canonical_field = 'check_number'
                THEN cl.raw_value
            END
        ) AS check_number,
        MAX(
            CASE
                WHEN cl.canonical_field = 'status'
                THEN cl.raw_value
            END
        ) AS status
    FROM canon_long cl
    INNER JOIN metadata_layout_controls mlc
        ON cl.source_system = mlc.source_system
       AND cl.account_id = mlc.account_id
       AND cl.layout_id = mlc.layout_id
    GROUP BY
        cl.source_file_path,
        cl.source_file_name,
        cl.source_system,
        cl.account_id,
        cl.file_start_dt,
        cl.file_end_dt,
        cl.layout_id,
        lower(trim(mlc.amount_model)),
        cl.derived_row_serial
),
parsed AS (
    SELECT
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        amount_model,
        derived_row_serial,
        transaction_date,
        description,
        amount_value,
        debit_amount_value,
        credit_amount_value,
        TRY_CAST(
            NULLIF(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            amount_value,
                            '[$,]',
                            ''
                        ),
                        '^\((.*)\)$',
                        '-$1'
                    )
                ),
                ''
            ) AS DECIMAL(18,2)
        ) AS parsed_amount,
        TRY_CAST(
            NULLIF(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            debit_amount_value,
                            '[$,]',
                            ''
                        ),
                        '^\((.*)\)$',
                        '-$1'
                    )
                ),
                ''
            ) AS DECIMAL(18,2)
        ) AS parsed_debit_amount,
        TRY_CAST(
            NULLIF(
                TRIM(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            credit_amount_value,
                            '[$,]',
                            ''
                        ),
                        '^\((.*)\)$',
                        '-$1'
                    )
                ),
                ''
            ) AS DECIMAL(18,2)
        ) AS parsed_credit_amount,
        check_number,
        status
    FROM wide
)
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    amount_model,
    derived_row_serial,
    transaction_date,
    description,
    amount_value AS amount,
    parsed_amount AS amount_d_source,
    debit_amount_value AS debit_amount,
    parsed_debit_amount AS debit_amount_d,
    credit_amount_value AS credit_amount,
    parsed_credit_amount AS credit_amount_d,
    CASE
        WHEN amount_value IS NOT NULL THEN 'amount'
        WHEN credit_amount_value IS NOT NULL THEN 'credit_amount'
        WHEN debit_amount_value IS NOT NULL THEN 'debit_amount'
        ELSE NULL
    END AS amount_source_field,
    CAST(
        CASE amount_model
            WHEN 'single_signed'
                THEN parsed_amount
            WHEN 'single_debit_positive'
                THEN parsed_amount * -1
            WHEN 'split_signed'
                THEN COALESCE(parsed_credit_amount, parsed_debit_amount)
            WHEN 'split_unsigned'
                THEN CASE
                    WHEN parsed_credit_amount IS NOT NULL
                        THEN ABS(parsed_credit_amount)
                    WHEN parsed_debit_amount IS NOT NULL
                        THEN ABS(parsed_debit_amount) * -1
                    ELSE NULL
                END
            ELSE NULL
        END
        AS DECIMAL(18,2)
    ) AS amount_d,
    check_number,
    status
FROM parsed
WHERE
    UPPER(TRIM(transaction_date)) <> 'DATE'
    AND UPPER(
        TRIM(
            COALESCE(
                amount_value,
                debit_amount_value,
                credit_amount_value,
                ''
            )
        )
    ) NOT IN ('AMOUNT', 'CREDIT', 'DEBIT');
