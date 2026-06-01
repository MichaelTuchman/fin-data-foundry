-- 
-- downloader.sql
-- download the transaction file for further analysis at home
--
-- input: vw_transactions_analysis
-- can be used to download straight into R

select account_label,institution,transaction_date,description,amount
from vw_transactions_analysis
order by account_label,institution,transaction_date;

