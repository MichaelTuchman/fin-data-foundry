CREATE OR REPLACE VIEW canon_wide AS
WITH long_with_money AS (
    SELECT
        l.source_file_path,
        l.source_file_name,
        l.source_system,
        l.account_id,
        l.file_start_dt,
        l.file_end_dt,
        l.layout_id,
        l.derived_row_serial,
        l.canonical_field,
        l.raw_value,
        l.validation_type,
        l.validation_passed,
        lc.debit_amount_convention,
        CASE
            WHEN l.validation_type = 'money'
             AND NULLIF(trim(l.raw_value), '') IS NOT NULL THEN
                TRY_CAST(
                    regexp_replace(
                        regexp_replace(
                            regexp_replace(
                                trim(l.raw_value),
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
    FROM canon_long l
    LEFT JOIN metadata_layout_controls lc
        ON lc.source_system = l.source_system
       AND lc.account_id = l.account_id
       AND lc.layout_id = l.layout_id
    WHERE l.validation_passed = true
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

        max(CASE WHEN canonical_field = 'amount' THEN NULLIF(trim(raw_value), '') END) AS amount,
        max(CASE WHEN canonical_field = 'amount' THEN money_value_d END) AS signed_amount_d,

        max(CASE WHEN canonical_field = 'debit_amount' THEN NULLIF(trim(raw_value), '') END) AS debit_amount,
        max(CASE WHEN canonical_field = 'debit_amount' THEN money_value_d END) AS debit_amount_d,

        max(CASE WHEN canonical_field = 'credit_amount' THEN NULLIF(trim(raw_value), '') END) AS credit_amount,
        max(CASE WHEN canonical_field = 'credit_amount' THEN money_value_d END) AS credit_amount_d,

        max(CASE WHEN canonical_field = 'check_number' THEN raw_value END) AS check_number,
        max(CASE WHEN canonical_field = 'status' THEN raw_value END) AS status,

        max(NULLIF(trim(debit_amount_convention), '')) AS debit_amount_convention
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
            CASE
                WHEN lower(coalesce(debit_amount_convention, 'negative')) = 'positive' THEN
                    coalesce(credit_amount_d, CAST(0 AS decimal(18,2)))
                      - coalesce(debit_amount_d, CAST(0 AS decimal(18,2)))
                ELSE
                    coalesce(credit_amount_d, CAST(0 AS decimal(18,2)))
                      + coalesce(debit_amount_d, CAST(0 AS decimal(18,2)))
            END
        ) AS decimal(18,2)
    ) AS amount_d,

    check_number,
    status
FROM wide_base;
