-- this is the final cross-bank analy sis dataset
-- transaction_date
-- description
-- amount
-- account metadata


CREATE OR REPLACE VIEW vw_transactions_analysis AS

SELECT
    cl.source_system,
    cl.account_id,

    a.account_label,
    a.account_type,
    a.institution,

    cl.source_path,
    cl.file_name,
    cl.file_start_yyyymm,
    cl.file_end_yyyymm,
    cl.source_row_number,
    cl.layout_id,

    CAST(
        date_parse(
            MAX(
                CASE
                    WHEN cl.canonical_field = 'transaction_date'
                    THEN cl.raw_value
                END
            ),
            '%c/%e/%Y'
        ) AS date
    ) AS transaction_date,

    MAX(
        CASE
            WHEN cl.canonical_field = 'description'
            THEN cl.raw_value
        END
    ) AS description,

    CAST(
        regexp_replace(
            MAX(
                CASE
                    WHEN cl.canonical_field = 'amount'
                    THEN cl.raw_value
                END
            ),
            '[$,]',
            ''
        ) AS decimal(12,2)
    ) AS amount

FROM vw_transactions_canonical_long cl

INNER JOIN metadata_accounts a
  ON cl.source_system = a.source_system
 AND cl.account_id = a.account_id

GROUP BY
    cl.source_system,
    cl.account_id,
    a.account_label,
    a.account_type,
    a.institution,
    cl.source_path,
    cl.file_name,
    cl.file_start_yyyymm,
    cl.file_end_yyyymm,
    cl.source_row_number,
    cl.layout_id;
