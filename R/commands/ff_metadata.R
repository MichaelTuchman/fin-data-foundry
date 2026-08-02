#!/usr/bin/env Rscript

get_script_path <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)

  if (length(file_arg) != 1L) {
    stop(
      "Could not determine script path; run this via Rscript.",
      call. = FALSE
    )
  }

  normalizePath(
    sub("^--file=", "", file_arg),
    winslash = "/",
    mustWork = TRUE
  )
}

script_path <- get_script_path()
foundry_root <- dirname(dirname(dirname(script_path)))

source(
  file.path(
    foundry_root,
    "R",
    "execution",
    "build_metadata_csv.R"
  )
)

source(
  file.path(
    foundry_root,
    "R",
    "platform",
    "publish_metadata_s3.R"
  )
)

print_usage <- function() {
  message(
    paste(
      "Usage:",
      "  Rscript R/commands/ff_metadata.R build",
      "  Rscript R/commands/ff_metadata.R publish [s3://bucket/metadata]",
      "  Rscript R/commands/ff_metadata.R deploy  [s3://bucket/metadata]",
      "",
      "The metadata S3 root may also be supplied with",
      "FF_METADATA_S3_URI.",
      sep = "\n"
    )
  )
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1L) {
  print_usage()
  quit(status = 1L, save = "no")
}

command <- args[[1]]
positional <- args[-1]

resolve_s3_uri <- function() {
  uri <- if (length(positional) >= 1L) {
    positional[[1]]
  } else {
    Sys.getenv(
      "FF_METADATA_S3_URI",
      unset = ""
    )
  }

  if (!nzchar(uri)) {
    stop(
      paste(
        "No metadata S3 root was provided.",
        "Pass s3://bucket/metadata after the command",
        "or set FF_METADATA_S3_URI."
      ),
      call. = FALSE
    )
  }

  uri
}

run <- function() {
  switch(
    command,
    build = build_metadata_csv(foundry_root),
    publish = publish_metadata_s3(
      foundry_root,
      resolve_s3_uri()
    ),
    deploy = {
      build_metadata_csv(foundry_root)
      publish_metadata_s3(
        foundry_root,
        resolve_s3_uri()
      )
    },
    {
      message(
        sprintf(
          "Unknown command: %s",
          command
        )
      )
      print_usage()
      quit(status = 1L, save = "no")
    }
  )
}

tryCatch(
  run(),
  error = function(e) {
    message(
      sprintf(
        "Error: %s",
        conditionMessage(e)
      )
    )
    quit(status = 1L, save = "no")
  }
)
