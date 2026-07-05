CREATE OR REPLACE VIEW canon_wide AS
WITH long_with_money AS (
    SELECT
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial,
        canonical_field,
        raw_value,
        validation_type,
        validation_passed,
        CASE
            WHEN validation_type = 'money' THEN
                TRY_CAST(
                    regexp_replace(
                        regexp_replace(
                            regexp_replace(
                                trim(raw_value),
                                '[$,]',
                                ''
                            ),
                            '^\((.*)\)$',
                            '-$1'
                        ),
                        '^$',
                        '0'
                    ) AS decimal(18,2)
                )
            ELSE NULL
        END AS money_value_d
    FROM canon_long
    WHERE validation_passed = true
),
wide_base AS (
    SELECT
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial,

        max(CASE WHEN canonical_field = 'transaction_date' THEN raw_value END) AS transaction_date,
        max(CASE WHEN canonical_field = 'description' THEN raw_value END) AS description,

        max(CASE WHEN canonical_field = 'amount' THEN raw_value END) AS amount,
        max(CASE WHEN canonical_field = 'amount' THEN money_value_d END) AS signed_amount_d,

        max(CASE WHEN canonical_field = 'debit_amount' THEN raw_value END) AS debit_amount,
        max(CASE WHEN canonical_field = 'debit_amount' THEN money_value_d END) AS debit_amount_d,

        max(CASE WHEN canonical_field = 'credit_amount' THEN raw_value END) AS credit_amount,
        max(CASE WHEN canonical_field = 'credit_amount' THEN money_value_d END) AS credit_amount_d,

        max(CASE WHEN canonical_field = 'check_number' THEN raw_value END) AS check_number,
        max(CASE WHEN canonical_field = 'status' THEN raw_value END) AS status
    FROM long_with_money
    GROUP BY
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial
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

    coalesce(
        amount,
        credit_amount,
        debit_amount
    ) AS amount,

    CAST(
        coalesce(
            signed_amount_d,
            coalesce(credit_amount_d, CAST(0 AS decimal(18,2)))
              - coalesce(debit_amount_d, CAST(0 AS decimal(18,2)))
        ) AS decimal(18,2)
    ) AS amount_d,

    check_number,
    status
FROM wide_base;
