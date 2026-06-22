# download_athena_view.R
#
# Downloads a view from AWS Athena and saves it as an .rds file.
#
# Prerequisites:
#   install.packages(c("noctua", "DBI"))
#   AWS credentials configured via ~/.aws/credentials or environment variables
#   (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION)
#
# Usage:
#   source("RCode/download_athena_view.R")
#   df <- download_athena_view(s3_staging_dir = "s3://my-bucket/athena-staging/")

download_athena_view <- function(
  database       = "finances",
  view           = "downloader",
  s3_staging_dir,
  aws_region     = "us-east-1",
  output_dir     = path.expand("~/Downloads"),
  output_file    = NULL
) {
  if (!requireNamespace("noctua", quietly = TRUE))
    stop("Package 'noctua' is required. Install with: install.packages('noctua')")
  if (!requireNamespace("DBI", quietly = TRUE))
    stop("Package 'DBI' is required. Install with: install.packages('DBI')")

  message("Connecting to Athena (database: ", database, ", view: ", view, ") ...")

  con <- DBI::dbConnect(
    noctua::athena(),
    region_name    = aws_region,
    s3_staging_dir = s3_staging_dir,
    schema_name    = database
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  sql <- paste0("SELECT * FROM ", view)
  message("Running: ", sql)
  df  <- DBI::dbGetQuery(con, sql)
  message("Retrieved ", nrow(df), " rows, ", ncol(df), " columns.")

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  if (is.null(output_file)) {
    stamp       <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_file <- paste0(view, "_", stamp, ".rds")
  }

  path <- file.path(output_dir, output_file)
  saveRDS(df, path)
  message("Saved to: ", path)

  invisible(df)
}
