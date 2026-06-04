create or replace view vw_transactions_analysis as
select
    source_system,
    account_id,
    row_id,

    try_cast(transaction_date as date) as transaction_date,
    description,

    try_cast(
        regexp_replace(amount, '[,$]', '')
        as decimal(18,2)
    ) as amount,

    check_number

from vw_transactions_wide;
