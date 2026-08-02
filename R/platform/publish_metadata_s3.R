publish_metadata_s3 <- function(
    foundry_root,
    s3_root_uri
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

  artifact_routes <- c(
    metadata_accounts.csv = "accounts",
    metadata_layout_controls.csv = "layout_controls",
    metadata_layout_cols.csv = "layout_cols",
    metadata_transaction_type_rules.csv = "transaction_type_rules"
  )

  local_files <- file.path(
    generated_dir,
    names(artifact_routes)
  )

  missing_files <- local_files[!file.exists(local_files)]

  if (length(missing_files) > 0L) {
    stop(
      paste(
        c(
          "Required generated metadata files are missing:",
          paste0("  ", missing_files),
          "Run the metadata build before publishing."
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  if (!grepl("^s3://", s3_root_uri)) {
    stop(
      "'s3_root_uri' must begin with s3://",
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

  s3_root_uri <- sub("/+$", "", s3_root_uri)

  for (artifact_name in names(artifact_routes)) {
    local_file <- file.path(
      generated_dir,
      artifact_name
    )

    destination <- paste0(
      s3_root_uri,
      "/",
      artifact_routes[[artifact_name]],
      "/",
      artifact_name
    )

    result <- system2(
      command = aws_path,
      args = c(
        "s3",
        "cp",
        local_file,
        destination,
        "--only-show-errors"
      ),
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
            sprintf(
              "Metadata publication failed for %s.",
              artifact_name
            ),
            result
          ),
          collapse = "\n"
        ),
        call. = FALSE
      )
    }

    message(
      sprintf(
        "Published %s to %s",
        artifact_name,
        destination
      )
    )
  }

  invisible(
    setNames(
      paste0(
        s3_root_uri,
        "/",
        unname(artifact_routes),
        "/",
        names(artifact_routes)
      ),
      names(artifact_routes)
    )
  )
}
