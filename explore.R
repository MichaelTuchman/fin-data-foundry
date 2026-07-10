library(DBI)
library(RAthena)
library(reticulate)
library(data.table)
library(knitr)
library(scales)

options(rstudio.connectionObserver.errorsSuppressed = TRUE)
# Run athena view helper ----
run_athena_view <- function(file_name, conn) {
  if (!file.exists(file_name)) {
    stop("SQL file not found: ", file_name)
  }
  
  sql <- paste(
    readLines(file_name, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  
  sql <- sub("^\ufeff", "", sql)
  
  if (!grepl(
    "^\\s*CREATE\\s+OR\\s+REPLACE\\s+VIEW\\b",
    sql,
    ignore.case = TRUE
  )) {
    stop("The SQL file must begin with CREATE OR REPLACE VIEW.")
  }
  
  DBI::dbExecute(conn, sql)
  
  message("Successfully executed: ", file_name)
  
  invisible(TRUE)
}
# end of helper functions ----

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
