create or replace view vw_transactions_wide as
select
    source_system,
    account_id,
    source_path,
    file_name,
    file_start_yyyymm,
    file_end_yyyymm,
    source_row_number,
    layout_id,

    max(case when canonical_field = 'transaction_date' then raw_value end) as transaction_date,
    max(case when canonical_field = 'description'      then raw_value end) as description,
    max(case when canonical_field = 'amount'           then raw_value end) as amount,
    max(case when canonical_field = 'check_number'     then raw_value end) as check_number

from vw_transactions_canonical_long
group by
    source_system,
    account_id,
    source_path,
    file_name,
    file_start_yyyymm,
    file_end_yyyymm,
    source_row_number,
    layout_id;
