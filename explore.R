library(DBI)
library(RAthena)
library(reticulate)
library(data.table)
library(knitr)
library(scales)

options(rstudio.connectionObserver.errorsSuppressed = TRUE)

py_require(c("boto3", "numpy"))

con3 <- dbConnect(
  RAthena::athena(),
  schema_name = 'finances',
  s3_staging_dir = "s3://mft-query-results/",
  region_name = "us-east-1"
)

fetch_data<- function() {
  message('May take a few minutes to process all views and download')
downloader <- DBI::dbGetQuery(
  con3,
  "SELECT * FROM downloader"
) |> data.table()
setkey(downloader,account_label,account_type,transaction_date)
return(downloader) 
}

DBI::dbGetQuery(con3,"select * from finances.metadata_layout_controls") |> kable()

DT=fetch_data()




DT[,
           .(
             first = min(transaction_date),
             last  = max(transaction_date),
             net   = scales::dollar(sum(amount),accuracy = 0.01),
             xcount = .N
           ),
           by = .(account_type,transaction_type)
] |> kable(align = "llllrr")


top3_purchases_by_month <- function(dt, by_extra = character(0)) {
  by_cols <- c("transaction_year", "transaction_month", by_extra)
  dt[amount < 0,
     .SD[order(amount)][seq_len(min(3L, .N))],
     by = by_cols
  ]
}


# Add account_id as an additional group
DT[order(amount)][transaction_date>='2026-01-01' & transaction_type=='purchase'&account_type=='credit_card',.(account_label,description,transaction_date,amount)]

