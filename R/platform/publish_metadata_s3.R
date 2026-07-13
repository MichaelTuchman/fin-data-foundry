# publish_metadata_s3.R
# must have aws cli configured for this to work.  


publish_metadata_s3 <- function(
    foundry_root,
    s3_uri,
    delete_remote_files = FALSE
) {
  foundry_root <- normalizePath(
    foundry_root,
    winslash = "/",
    mustWork = TRUE
  )
  
  generated_dir <- file.path(
    foundry_root,
    "metadata",
    "generated"
  )
  
  if (!dir.exists(generated_dir)) {
    stop(
      sprintf(
        "Generated metadata directory does not exist: %s",
        generated_dir
      ),
      call. = FALSE
    )
  }
  
  csv_files <- list.files(
    path = generated_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(csv_files) == 0L) {
    stop(
      sprintf(
        "No generated CSV files found in: %s",
        generated_dir
      ),
      call. = FALSE
    )
  }
  
  if (!grepl("^s3://", s3_uri)) {
    stop(
      "'s3_uri' must begin with s3://",
      call. = FALSE
    )
  }
  
  aws_path <- Sys.which("aws")
  
  if (!nzchar(aws_path)) {
    stop(
      "AWS CLI was not found on the system PATH.",
      call. = FALSE
    )
  }
  
  s3_uri <- sub("/+$", "", s3_uri)
  
  arguments <- c(
    "s3",
    "sync",
    generated_dir,
    s3_uri,
    "--exclude",
    "*",
    "--include",
    "*.csv"
  )
  
  if (isTRUE(delete_remote_files)) {
    arguments <- c(
      arguments,
      "--delete"
    )
  }
  
  result <- system2(
    command = aws_path,
    args = arguments,
    stdout = TRUE,
    stderr = TRUE
  )
  
  exit_status <- attr(result, "status")
  
  if (is.null(exit_status)) {
    exit_status <- 0L
  }
  
  if (exit_status != 0L) {
    stop(
      paste(
        c(
          "Metadata publication to S3 failed.",
          result
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }
  
  message(
    sprintf(
      "Published metadata CSV files to %s",
      s3_uri
    )
  )
  
  invisible(result)
}