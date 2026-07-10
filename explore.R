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
  "SELECT * FROM trans_export"
) |> data.table()
setkey(downloader,account_label,account_type,transaction_date)
return(downloader) 
}

DT = fetch_data()
