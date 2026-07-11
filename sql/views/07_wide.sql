CREATE OR REPLACE VIEW canon_wide AS
WITH wide AS (
    SELECT
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial,
        MAX(
            CASE
                WHEN canonical_field = 'transaction_date'
                THEN raw_value
            END
        ) AS transaction_date,
        MAX(
            CASE
                WHEN canonical_field = 'description'
                THEN raw_value
            END
        ) AS description,
        NULLIF(
            TRIM(
                MAX(
                    CASE
                        WHEN canonical_field = 'amount'
                        THEN raw_value
                    END
                )
            ),
            ''
        ) AS amount_value,
        NULLIF(
            TRIM(
                MAX(
                    CASE
                        WHEN canonical_field = 'debit_amount'
                        THEN raw_value
                    END
                )
            ),
            ''
        ) AS debit_amount_value,
        NULLIF(
            TRIM(
                MAX(
                    CASE
                        WHEN canonical_field = 'credit_amount'
                        THEN raw_value
                    END
                )
            ),
            ''
        ) AS credit_amount_value,
        MAX(
            CASE
                WHEN canonical_field = 'check_number'
                THEN raw_value
            END
        ) AS check_number,
        MAX(
            CASE
                WHEN canonical_field = 'status'
                THEN raw_value
            END
        ) AS status
    FROM canon_long
    GROUP BY
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial
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
    derived_row_serial,
    transaction_date,
    description,
    COALESCE(
        amount_value,
        debit_amount_value,
        credit_amount_value
    ) AS amount,
    CAST(
        CASE
            WHEN parsed_amount IS NOT NULL
                THEN parsed_amount
            WHEN parsed_debit_amount IS NOT NULL
              OR parsed_credit_amount IS NOT NULL
                THEN COALESCE(parsed_debit_amount, DECIMAL '0.00')
                   - COALESCE(parsed_credit_amount, DECIMAL '0.00')
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