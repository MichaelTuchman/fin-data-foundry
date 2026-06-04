-- 2. vw_raw_transactions_long

CREATE OR REPLACE VIEW vw_raw_transactions_long AS
SELECT
    source_system,
    account_id,
    account_label,
    account_type,
    institution,
    source_path,
    file_name,
    file_start_yyyymm,
    file_end_yyyymm,
    source_row_number,
    u.column_position,
    u.raw_value
FROM vw_raw_csv_file_context r
CROSS JOIN UNNEST(
    ARRAY[1,2,3,4,5,6,7,8,9,10],
    ARRAY[
        r.col01,
        r.col02,
        r.col03,
        r.col04,
        r.col05,
        r.col06,
        r.col07,
        r.col08,
        r.col09,
        r.col10
    ]
) AS u(column_position, raw_value);
