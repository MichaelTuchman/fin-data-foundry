create view layered_rowcheck as
WITH
fc AS (
    SELECT 'file_context' AS layer, account_id, count(DISTINCT derived_row_serial) AS n_rows
    FROM file_context
    WHERE source_system = 'your_source_id' AND account_id = 'your_account_id'
    GROUP BY account_id
),
lm AS (
    SELECT 'layout_match' AS layer, account_id, count(DISTINCT derived_row_serial) AS n_rows
    FROM layout_match
    WHERE source_system = 'your_source_id' AND account_id = 'your_account_id'
    GROUP BY account_id
),
cl AS (
    SELECT 'canon_long' AS layer, account_id, count(DISTINCT derived_row_serial) AS n_rows
    FROM canon_long
    WHERE source_system = 'your_source_id' AND account_id = 'your_account_id'
    GROUP BY account_id
),
ta AS (
    SELECT 'trans_analy' AS layer, account_id, count(DISTINCT derived_row_serial) AS n_rows
    FROM trans_analy
    WHERE source_system = 'your_source_id' AND account_id = 'your_account_id'
    GROUP BY account_id
),
tt AS (
    SELECT 'trans_typed' AS layer, account_id, count(DISTINCT derived_row_serial) AS n_rows
    FROM trans_typed
    WHERE source_system = 'your_source_id' AND account_id = 'your_account_id'
    GROUP BY account_id
)
SELECT * FROM fc
UNION ALL SELECT * FROM lm
UNION ALL SELECT * FROM cl
UNION ALL SELECT * FROM ta
UNION ALL SELECT * FROM tt
ORDER BY layer;
