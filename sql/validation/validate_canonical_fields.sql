SELECT
    source_system,
    account_id,
    source_row_number,
    canonical_field,
    COUNT(*) AS n
FROM vw_transactions_canonical_long
GROUP BY
    source_system,
    account_id,
    source_row_number,
    canonical_field
HAVING COUNT(*) > 1;
