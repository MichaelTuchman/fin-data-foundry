CREATE OR REPLACE VIEW finances.canon_wide AS
WITH valid_rows AS (
    SELECT
        source_file_path,
        derived_row_serial
    FROM finances.canon_long
    GROUP BY
        source_file_path,
        derived_row_serial
    HAVING SUM(
        CASE
            WHEN required = 'true'
             AND validation_passed = false
            THEN 1
            ELSE 0
        END
    ) = 0
)
SELECT
    cl.source_file_path,
    cl.source_file_name,
    cl.source_system,
    cl.account_id,
    cl.file_start_dt,
    cl.file_end_dt,
    cl.layout_id,
    cl.derived_row_serial,

    MAX(CASE
        WHEN lower(cl.canonical_field) = 'transaction_date'
        THEN cl.raw_value
    END) AS transaction_date,

    MAX(CASE
        WHEN lower(cl.canonical_field) = 'description'
        THEN cl.raw_value
    END) AS description,

    MAX(CASE
        WHEN lower(cl.canonical_field) = 'amount'
        THEN cl.raw_value
    END) AS amount,

    MAX(CASE
        WHEN lower(cl.canonical_field) = 'amount'
        THEN TRY_CAST(
            CASE
                WHEN cl.raw_value IS NULL OR trim(cl.raw_value) = '' THEN NULL
                WHEN regexp_like(trim(cl.raw_value), '^[(].*[)]$') THEN
                    '-' || regexp_replace(
                        regexp_replace(trim(cl.raw_value), '[^0-9.,-]', ''),
                        ',',
                        ''
                    )
                ELSE
                    regexp_replace(
                        regexp_replace(trim(cl.raw_value), '[^0-9.,-]', ''),
                        ',',
                        ''
                    )
            END
            AS decimal(18,2)
        )
    END) AS amount_d,

    MAX(CASE
        WHEN lower(cl.canonical_field) = 'check_number'
        THEN cl.raw_value
    END) AS check_number,

    MAX(CASE
        WHEN lower(cl.canonical_field) = 'status'
        THEN cl.raw_value
    END) AS status

FROM finances.canon_long cl
JOIN valid_rows vr
  ON cl.source_file_path = vr.source_file_path
 AND cl.derived_row_serial = vr.derived_row_serial
GROUP BY
    cl.source_file_path,
    cl.source_file_name,
    cl.source_system,
    cl.account_id,
    cl.file_start_dt,
    cl.file_end_dt,
    cl.layout_id,
    cl.derived_row_serial;
