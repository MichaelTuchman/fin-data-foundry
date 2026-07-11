CREATE OR REPLACE VIEW trans_export AS
SELECT
source_file_name,
source_system,
account_label,
account_type,
institution,
transaction_dt,
source_description,
description,
amount_d as amount,
check_number,
status,
transaction_type,
transaction_subtype,
matched_transaction_type_rule_id
FROM trans_normalized;