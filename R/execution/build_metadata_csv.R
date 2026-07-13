# build_metadata_csv.R
# convert yaml metadata in source to platform specific file
# in generated.


build_metadata_csv <- function(
    foundry_root,
    filename_prefix = "metadata_"
) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required.", call. = FALSE)
  }
  
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Package 'data.table' is required.", call. = FALSE)
  }
  
  foundry_root <- normalizePath(
    foundry_root,
    winslash = "/",
    mustWork = TRUE
  )
  
  source_dir <- file.path(
    foundry_root,
    "metadata",
    "source"
  )
  
  generated_dir <- file.path(
    foundry_root,
    "metadata",
    "generated"
  )
  
  if (!dir.exists(source_dir)) {
    stop(
      sprintf(
        "Metadata source directory does not exist: %s",
        source_dir
      ),
      call. = FALSE
    )
  }
  
  yaml_files <- list.files(
    path = source_dir,
    pattern = "\\.(yml|yaml)$",
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(yaml_files) == 0L) {
    stop(
      sprintf(
        "No YAML metadata files found in: %s",
        source_dir
      ),
      call. = FALSE
    )
  }
  
  dir.create(
    generated_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  output_files <- character(length(yaml_files))
  
  for (i in seq_along(yaml_files)) {
    yaml_file <- yaml_files[[i]]
    metadata <- yaml::read_yaml(yaml_file)
    
    if (!is.list(metadata) || is.null(names(metadata))) {
      stop(
        sprintf(
          "YAML file must contain a named top-level mapping: %s",
          yaml_file
        ),
        call. = FALSE
      )
    }
    
    collection_names <- setdiff(
      names(metadata),
      "version"
    )
    
    if (length(collection_names) != 1L) {
      stop(
        sprintf(
          paste0(
            "YAML file must contain exactly one data collection ",
            "in addition to 'version': %s"
          ),
          yaml_file
        ),
        call. = FALSE
      )
    }
    
    collection_name <- collection_names[[1]]
    records <- metadata[[collection_name]]
    
    if (!is.list(records) || length(records) == 0L) {
      stop(
        sprintf(
          "Collection '%s' is empty or invalid in: %s",
          collection_name,
          yaml_file
        ),
        call. = FALSE
      )
    }
    
    rows <- lapply(
      records,
      function(record) {
        if (!is.list(record) || is.null(names(record))) {
          stop(
            sprintf(
              "Invalid record in YAML file: %s",
              yaml_file
            ),
            call. = FALSE
          )
        }
        
        record[
          vapply(record, is.null, logical(1))
        ] <- list(NA)
        
        record
      }
    )
    
    metadata_table <- data.table::rbindlist(
      rows,
      use.names = TRUE,
      fill = TRUE
    )
    
    input_stem <- tools::file_path_sans_ext(
      basename(yaml_file)
    )
    
    output_file <- file.path(
      generated_dir,
      paste0(
        filename_prefix,
        input_stem,
        ".csv"
      )
    )
    
    data.table::fwrite(
      metadata_table,
      file = output_file,
      na = "",
      quote = "auto",
      logical01 = FALSE
    )
    
    output_files[[i]] <- output_file
  }
  
  names(output_files) <- basename(yaml_files)
  
  message(
    sprintf(
      "Generated %d metadata CSV file(s) in %s",
      length(output_files),
      generated_dir
    )
  )
  
  invisible(output_files)
}