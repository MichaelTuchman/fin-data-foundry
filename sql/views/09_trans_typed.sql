
CREATE OR REPLACE VIEW trans_typed AS
WITH rule_matches AS (
    SELECT
        t.*,
        r.rule_id AS matched_transaction_type_rule_id,
        r.rule_priority AS matched_transaction_type_rule_priority,
        r.transaction_type,
        r.transaction_subtype,
        ROW_NUMBER() OVER (
            PARTITION BY
                t.source_file_path,
                t.derived_row_serial
            ORDER BY
                r.rule_priority,
                r.rule_id
        ) AS rule_rank
    FROM trans_analy t
    JOIN metadata_transaction_type_rules r
        ON r.active = true
       AND (r.source_system = 'any' OR r.source_system = t.source_system)
       AND (r.account_id = 'any' OR r.account_id = t.account_id)
       AND (r.account_type = 'any' OR r.account_type = t.account_type)
       AND (
            r.amount_sign = 'any'
            OR (r.amount_sign = 'positive' AND t.amount_d > 0)
            OR (r.amount_sign = 'negative' AND t.amount_d < 0)
       )
       AND (
            r.description_match_type = 'any'
            OR (
                r.description_match_type = 'contains'
                AND strpos(upper(t.description), upper(r.description_pattern)) > 0
            )
            OR (
                r.description_match_type = 'exact'
                AND upper(t.description) = upper(r.description_pattern)
            )
            OR (
                r.description_match_type = 'regex'
                AND regexp_like(upper(t.description), upper(r.description_pattern))
            )
       )
)
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    account_label,
    account_type,
    institution,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,
    transaction_date,
    transaction_dt,
    description,
    amount,
    amount_d,
    check_number,
    status,
    transaction_type,
    transaction_subtype,
    matched_transaction_type_rule_id,
    matched_transaction_type_rule_priority
FROM rule_matches
WHERE rule_rank = 1;
