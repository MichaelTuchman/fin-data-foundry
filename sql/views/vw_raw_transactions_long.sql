-- Input:
--     vw_raw_csv_file_context
-- 
-- Output:
--     source_system
--     account_id
--     source_path
--     source_row_number
--     column_position
--     raw_value
CREATE OR REPLACE VIEW vw_raw_transactions_long AS

WITH known_accounts AS (
    SELECT
        fc.source_system,
        fc.account_id,
        fc.source_path,
        fc.file_name,
        fc.file_start_yyyymm,
        fc.file_end_yyyymm,

        fc.col01, fc.col02, fc.col03, fc.col04, fc.col05,
        fc.col06, fc.col07, fc.col08, fc.col09, fc.col10
    FROM vw_raw_csv_file_context fc
    INNER JOIN metadata_accounts a
      ON fc.source_system = a.source_system
     AND fc.account_id = a.account_id
),

numbered AS (
    SELECT
        *,
        row_number() OVER (
            PARTITION BY source_path
            ORDER BY col01, col02, col03, col04, col05
        ) AS source_row_number
    FROM known_accounts
)

SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 1 AS column_position, col01 AS raw_value FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 2, col02 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 3, col03 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 4, col04 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 5, col05 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 6, col06 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 7, col07 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 8, col08 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 9, col09 FROM numbered
UNION ALL
SELECT source_system, account_id, source_path, file_name, file_start_yyyymm, file_end_yyyymm, source_row_number, 10, col10 FROM numbered;

