library(shiny)
library(DT)
library(lubridate)
library(shinyFiles)

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && nchar(a) > 0) a else b

is_valid_id <- function(s) grepl("^[A-Za-z_.][A-Za-z0-9_.]*$", trimws(s))

# Windows Downloads folder (works for any user)
default_downloads <- normalizePath(
  file.path(Sys.getenv("USERPROFILE"), "Downloads"),
  winslash = "/", mustWork = FALSE
)

# Filesystem roots for the directory browser
dir_roots <- c(
  Home      = normalizePath("~",    winslash = "/"),
  Downloads = default_downloads,
  C         = "C:/"
)

# --------------------------------------------------------------------------
# Read CSV with automatic retry on unmatched-quote warning.
# --------------------------------------------------------------------------
read_csv_safe <- function(path, header, sep, skip) {
  args <- list(
    file             = path,
    header           = header,
    sep              = sep,
    skip             = skip,
    stringsAsFactors = FALSE,
    check.names      = FALSE
  )
  warned <- FALSE
  df <- withCallingHandlers(
    do.call(read.csv, args),
    warning = function(w) {
      if (grepl("EOF within quoted string", conditionMessage(w))) {
        warned <<- TRUE
        invokeRestart("muffleWarning")
      }
    }
  )
  if (warned) {
    args$quote <- ""
    df <- do.call(read.csv, args)
    attr(df, "requoted") <- TRUE
  }
  df
}

# --------------------------------------------------------------------------
# Filename parser: impute source_system, account_id, valid_from from name
# --------------------------------------------------------------------------
parse_filename <- function(filename) {
  base <- tools::file_path_sans_ext(basename(filename))

  m <- regmatches(base, regexec("^([^_]+)_([^_]+)_([0-9]{8})$", base))[[1]]
  if (length(m) == 4) {
    d <- suppressWarnings(as.Date(m[4], format = "%Y%m%d"))
    if (!is.na(d)) return(list(source_system = m[2], account_id = m[3], valid_from = d))
  }

  m <- regmatches(base, regexec("^([^_]+)_([^_]+)_([0-9]{6})_([0-9]{6})$", base))[[1]]
  if (length(m) == 5) {
    d <- suppressWarnings(as.Date(paste0(m[4], "01"), format = "%Y%m%d"))
    if (!is.na(d)) return(list(source_system = m[2], account_id = m[3], valid_from = d))
  }

  NULL
}

# --------------------------------------------------------------------------
# Auto-detect rows to skip before the header
# --------------------------------------------------------------------------
detect_skip_rows <- function(filepath, sep = ",", n_scan = 30) {
  lines <- readLines(filepath, n = n_scan, warn = FALSE)
  if (length(lines) < 2) return(0L)
  field_counts <- vapply(lines, function(l) {
    length(strsplit(l, sep, fixed = TRUE)[[1]])
  }, integer(1))
  tbl         <- sort(table(field_counts), decreasing = TRUE)
  mode_count  <- as.integer(names(tbl)[1])
  first_match <- which(field_counts == mode_count)[1]
  max(0L, first_match - 1L)
}

# --------------------------------------------------------------------------
# Usage inference
# Values: "date", "money", "text"
# --------------------------------------------------------------------------

DATE_SPECS <- list(
  list(regexp = "^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$",         fmt = "%m/%d/%Y"),
  list(regexp = "^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$",          fmt = "%m/%d/%y"),
  list(regexp = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",              fmt = "%Y-%m-%d"),
  list(regexp = "^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{4}$",         fmt = "%d-%b-%Y"),
  list(regexp = "^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$",         fmt = "%d-%b-%y"),
  list(regexp = "^[A-Za-z]{3}\\s+[0-9]{1,2},?\\s+[0-9]{4}$", fmt = "%b %d, %Y")
)

# Detect which money style a column uses and return a style-specific regexp (no OR).
# Styles (mutually exclusive, checked in priority order):
#   parenthetical  (1,234.56)          -> ^\\(?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?\\)?$
#   dollar         -$1,234.56          -> ^-?\\$[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?$
#   comma          -1,234.56           -> ^-?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?$
#   plain          -1234.56            -> ^-?[0-9]+(\\.[0-9]{2})?$
money_regexp_for <- function(x_clean) {
  if (mean(grepl("^\\(", x_clean)) >= 0.10)
    return("^\\(?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?\\)?$")
  if (mean(grepl("\\$", x_clean)) >= 0.10)
    return("^-?\\$[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?$")
  if (mean(grepl(",", x_clean)) >= 0.10)
    return("^-?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?$")
  "^-?[0-9]+(\\.[0-9]{2})?$"
}

infer_usage_and_format <- function(x, col_name = "") {
  x_clean <- x[!is.na(x) & trimws(x) != ""]

  # 1. Date: pattern match on values
  if (length(x_clean) > 0) {
    for (ds in DATE_SPECS) {
      if (mean(grepl(ds$regexp, x_clean)) >= 0.70) {
        return(list(usage = "date", format = ds$fmt))
      }
    }
  }

  # 2. Money: strip $ , spaces and convert (n) -> -n, then try as.numeric.
  #    Qualify as money if >=70% parse AND >=50% have 2 decimal places
  #    OR >=10% have explicit money characters ($, comma, parens).
  if (length(x_clean) > 0) {
    stripped <- trimws(gsub("[$, ]", "", x_clean))
    stripped <- gsub("^\\((.+)\\)$", "-\\1", stripped)
    parsed   <- suppressWarnings(as.numeric(stripped))
    parse_rate      <- mean(!is.na(parsed))
    decimal_rate    <- mean(grepl("\\.[0-9]{2}$", stripped))
    money_char_rate <- mean(grepl("[$,()]", x_clean))
    if (parse_rate >= 0.70 && (decimal_rate >= 0.50 || money_char_rate >= 0.10)) {
      return(list(usage = "money", format = money_regexp_for(x_clean)))
    }
  }

  # 3. Date fallback: column name contains "date"
  if (grepl("date", col_name, ignore.case = TRUE)) {
    return(list(usage = "date", format = ""))
  }

  # 4. Default: text
  list(usage = "text", format = "")
}

infer_column_name <- function(raw_name) {
  nm <- trimws(raw_name)
  nm <- gsub("[^A-Za-z0-9 ]", " ", nm)
  nm <- trimws(gsub("\\s+", "_", nm))
  tolower(nm)
}

fix_colnames <- function(nms) {
  for (i in seq_along(nms)) {
    if (is.na(nms[i]) || trimws(nms[i]) == "") nms[i] <- paste0("col_", i)
  }
  nms
}

build_layout <- function(df, raw_names) {
  raw_names <- fix_colnames(raw_names)
  rows <- lapply(seq_along(raw_names), function(i) {
    col_data <- as.character(df[[i]])
    uf       <- infer_usage_and_format(col_data, raw_names[i])
    data.frame(
      original_name = raw_names[i],
      intended_name = infer_column_name(raw_names[i]),
      usage         = uf$usage,
      format        = uf$format,
      required      = TRUE,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

# --------------------------------------------------------------------------
# File helpers: append rows and deduplicate on key columns
# --------------------------------------------------------------------------

# Returns nrow of the final file, or stops with an informative message on error.
upsert_csv <- function(filepath, new_rows, key_cols) {
  if (file.exists(filepath)) {
    existing <- tryCatch(
      read.csv(filepath, stringsAsFactors = FALSE, check.names = FALSE),
      error = function(e) stop("Could not read ", basename(filepath), ": ", e$message)
    )
    message("upsert ", basename(filepath), ": existing=", nrow(existing),
            " new=", nrow(new_rows),
            " existing_cols=", paste(names(existing), collapse=","),
            " new_cols=", paste(names(new_rows), collapse=","))
    all_cols <- union(names(existing), names(new_rows))
    for (col in setdiff(all_cols, names(existing))) existing[[col]] <- NA
    for (col in setdiff(all_cols, names(new_rows))) new_rows[[col]] <- NA
    existing <- existing[, all_cols, drop = FALSE]
    new_rows <- new_rows[, all_cols, drop = FALSE]
    combined <- rbind(existing, new_rows)
    key_vals <- do.call(paste, c(combined[, key_cols, drop = FALSE], sep = "||"))
    combined <- combined[!duplicated(key_vals, fromLast = TRUE), ]
    message("upsert ", basename(filepath), ": combined=", nrow(combined))
  } else {
    combined <- new_rows
  }
  quote_cols <- which(names(combined) == "expected_pattern")
  tryCatch(
    write.table(combined, file = filepath, sep = ",", row.names = FALSE,
                col.names = TRUE, quote = if (length(quote_cols) > 0) quote_cols else FALSE),
    error = function(e) stop("Could not write ", basename(filepath), ": ", e$message)
  )
  nrow(combined)
}

# --------------------------------------------------------------------------
# UI
# --------------------------------------------------------------------------

ui <- fluidPage(

  tags$head(
    tags$style(HTML(paste0(
      "body { font-family: Arial, sans-serif; background: #f5f7fa; }",
      ".well { background: #fff; border: 1px solid #dde3ea; box-shadow: none; }",
      "h3 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 6px; }",
      ".btn-success { background-color: #27ae60; border-color: #219a52; }",
      ".field-error { color: #c0392b; font-size: 12px; margin-top: -10px; margin-bottom: 6px; }",
      "#status_msg { font-weight: bold; margin-top: 8px; }",
      "#save_msg { margin-top: 8px; }",
      ".dir-row { display: flex; gap: 6px; align-items: flex-end; }",
      ".dir-row .form-group { flex: 1; margin-bottom: 0; }"
    )))
  ),

  titlePanel("Financial Foundry Metadata Editor"),

  sidebarLayout(

    sidebarPanel(
      width = 3,

      h3("1. Load CSV"),
      fileInput("csv_file", "Choose CSV file", accept = ".csv"),
      checkboxInput("has_header", "File has header row", value = TRUE),
      selectInput("delimiter", "Delimiter",
        choices = c("Comma" = ",", "Tab" = "\t", "Semicolon" = ";", "Pipe" = "|"),
        selected = ","
      ),
      numericInput("skip_rows", "Rows to skip before header",
        value = 0, min = 0, step = 1),
      helpText("Auto-detected on file load. Override if needed."),
      actionButton("reload_csv", "Reload with this skip value",
        icon = icon("rotate"), class = "btn-sm"),
      hr(),

      h3("2. Account Metadata"),
      textInput("account_id", "Account ID",
        placeholder = "e.g. joint_checking"
      ),
      uiOutput("account_id_msg"),
      textInput("account_label", "Account Label",
        placeholder = "e.g. Wells Fargo Checking"
      ),
      selectInput("account_type", "Account Type",
        choices = c("checking" = "checking", "credit_card" = "credit_card"),
        selected = "checking"
      ),
      textInput("institution", "Institution",
        placeholder = "e.g. Wells Fargo"
      ),
      hr(),

      h3("3. Save Layout"),
      textInput("source_system", "Source System",
        placeholder = "e.g. Chase_Bank"
      ),
      uiOutput("source_system_msg"),
      textInput("layout_id", "Layout ID", value = "LAYOUT_A"),
      uiOutput("layout_id_msg"),
      dateInput("valid_from", "Layout Valid From",
        value  = Sys.Date(),
        format = "yyyy-mm-dd"
      ),
      textInput("valid_to", "Layout Valid To (optional)",
        placeholder = "YYYY-MM-DD"
      ),
      uiOutput("valid_to_msg"),

      # TODO: replace file output with direct S3 upload once bucket hierarchy is finalized
      tags$label("Output Directory"),
      tags$div(class = "dir-row",
        textInput("output_dir", label = NULL, value = default_downloads),
        shinyDirButton("browse_dir", "...", "Select output folder",
                       style = "margin-bottom:15px;")
      ),

      actionButton("save_layout", "Save Layout Files", class = "btn-success",
        icon = icon("floppy-disk")
      ),
      br(), br(),
      uiOutput("save_msg"),
      textOutput("status_msg")
    ),

    mainPanel(
      width = 9,

      conditionalPanel(
        condition = "output.file_loaded === 'yes'",

        wellPanel(
          h3("Column Layout -- edit cells directly; uncheck Required to omit a column"),
          helpText(
            "Usage: date, money, or text  |  ",
            "Format: lubridate string for dates, regexp for money  |  ",
            "Intended Name is free-text."
          ),
          DTOutput("layout_table"),
          br(),
          actionButton("reset_inference", "Reset to Inferred Values",
            icon = icon("rotate-left")
          )
        ),

        wellPanel(
          h3("Data Preview (first 10 rows)"),
          div(style = "overflow-x:auto;",
            DTOutput("data_preview")
          )
        ),

        # Checkbox toggle handler
        tags$script(HTML(paste0(
          "$(document).on('change', '#layout_table input[type=\"checkbox\"]', function() {",
          "  var idx = $(this).closest('tbody').find('tr').index($(this).closest('tr'));",
          "  Shiny.setInputValue('layout_checkbox_changed',",
          "    {row: idx + 1, checked: this.checked}, {priority: 'event'});",
          "});"
        )))
      ),

      conditionalPanel(
        condition = "output.file_loaded !== 'yes'",
        div(
          style = "text-align:center; padding: 80px; color: #7f8c8d;",
          h4("Load a CSV file to get started.")
        )
      )
    )
  )
)

# --------------------------------------------------------------------------
# Server
# --------------------------------------------------------------------------

server <- function(input, output, session) {

  rv <- reactiveValues(
    raw_df    = NULL,
    raw_names = NULL,
    layout    = NULL
  )

  # Directory browser
  shinyDirChoose(input, "browse_dir", roots = dir_roots, session = session)
  observeEvent(input$browse_dir, {
    path <- parseDirPath(dir_roots, input$browse_dir)
    if (length(path) > 0 && nchar(path) > 0) {
      updateTextInput(session, "output_dir",
        value = normalizePath(path, winslash = "/", mustWork = FALSE))
    }
  })

  # Auto-set account_type from account_id: credit card if mc/visa, else checking
  observe({
    s <- input$account_id
    if (is.null(s) || nchar(trimws(s)) == 0) return()

    parts <- strsplit(s, "_")[[1]]
    if (length(parts) >= 2)
      updateTextInput(session, "source_system", value = parts[1])

    sl <- tolower(s)
    if (grepl("visa|\\bmc\\b|mastercard|credit", sl)) {
      updateSelectInput(session, "account_type", selected = "credit_card")
    } else {
      updateSelectInput(session, "account_type", selected = "checking")
    }
  })

  # Inline validation messages
  output$source_system_msg <- renderUI({
    s <- input$source_system
    if (nchar(trimws(s)) == 0) return(NULL)
    if (!is_valid_id(s)) tags$div(class = "field-error",
      "Must start with a letter or _ and contain only letters, digits, _ or .")
  })

  output$account_id_msg <- renderUI({
    s <- input$account_id
    if (nchar(trimws(s)) == 0) return(NULL)
    if (!is_valid_id(s)) tags$div(class = "field-error",
      "Must start with a letter or _ and contain only letters, digits, _ or .")
  })

  output$layout_id_msg <- renderUI({
    s <- input$layout_id
    if (nchar(trimws(s)) == 0) return(NULL)
    if (!is_valid_id(s)) tags$div(class = "field-error",
      "Must start with a letter or _ and contain only letters, digits, _ or .")
  })

  output$valid_to_msg <- renderUI({
    s <- trimws(input$valid_to)
    if (nchar(s) == 0) return(NULL)
    d <- suppressWarnings(as.Date(s, format = "%Y-%m-%d"))
    if (is.na(d)) tags$div(class = "field-error", "Must be YYYY-MM-DD or leave blank.")
  })

  # Load CSV
  observeEvent(input$csv_file, {
    req(input$csv_file)
    tryCatch({
      skip <- detect_skip_rows(input$csv_file$datapath, sep = input$delimiter)
      updateNumericInput(session, "skip_rows", value = skip)

      df <- read_csv_safe(input$csv_file$datapath, input$has_header, input$delimiter, skip)
      if (isTRUE(attr(df, "requoted"))) {
        showNotification("Unmatched quotes detected -- re-parsed with quoting disabled.",
          type = "warning", duration = 6)
      }
      colnames(df) <- fix_colnames(colnames(df))
      rv$raw_df    <- df
      rv$raw_names <- colnames(df)
      rv$layout    <- build_layout(df, colnames(df))

      parsed <- parse_filename(input$csv_file$name)
      if (!is.null(parsed)) {
        updateTextInput(session, "source_system", value = parsed$source_system)
        updateTextInput(session, "account_id",    value = parsed$account_id)
        updateDateInput(session, "valid_from",    value = parsed$valid_from)
      }
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message),
        type = "error", duration = 8)
    })
  })

  # Reload with manually adjusted skip value
  observeEvent(input$reload_csv, {
    req(input$csv_file)
    tryCatch({
      df <- read_csv_safe(input$csv_file$datapath, input$has_header,
                          input$delimiter, max(0L, as.integer(input$skip_rows)))
      if (isTRUE(attr(df, "requoted"))) {
        showNotification("Unmatched quotes detected -- re-parsed with quoting disabled.",
          type = "warning", duration = 6)
      } else {
        showNotification("File reloaded.", type = "message")
      }
      colnames(df) <- fix_colnames(colnames(df))
      rv$raw_df    <- df
      rv$raw_names <- colnames(df)
      rv$layout    <- build_layout(df, colnames(df))
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message),
        type = "error", duration = 8)
    })
  })

  # Reset to inferred
  observeEvent(input$reset_inference, {
    req(rv$raw_df)
    rv$layout <- build_layout(rv$raw_df, rv$raw_names)
    showNotification("Layout reset to inferred values.", type = "message")
  })

  # Editable layout table with Required checkbox column
  output$layout_table <- renderDT({
    req(rv$layout)

    display <- rv$layout[, c("original_name", "intended_name", "usage", "format")]
    names(display) <- c("Original Name", "Intended Name", "Usage", "Format")

    # Render required as HTML checkboxes (col index 4)
    display[["Required"]] <- ifelse(
      rv$layout$required,
      '<input type="checkbox" checked>',
      '<input type="checkbox">'
    )

    dt <- datatable(
      display,
      rownames  = FALSE,
      escape    = FALSE,
      editable  = list(target = "cell", disable = list(columns = c(0, 4))),
      selection = "none",
      options   = list(
        pageLength = 25,
        dom        = "tp",
        columnDefs = list(
          list(width = "150px", targets = 0),
          list(width = "150px", targets = 1),
          list(width = "90px",  targets = 2),
          list(width = "250px", targets = 3),
          list(width = "70px",  targets = 4, className = "dt-center")
        )
      )
    )
    dt <- formatStyle(dt, "Usage",
      color = styleEqual(c("money", "date"), c("#8e44ad", "#c0392b")))
    dt <- formatStyle(dt, "Required",
      target = "row",
      backgroundColor = styleEqual(c(
        '<input type="checkbox">',
        '<input type="checkbox" checked>'
      ), c("#f0f0f0", "white")),
      color = styleEqual(c(
        '<input type="checkbox">',
        '<input type="checkbox" checked>'
      ), c("#aaaaaa", "inherit"))
    )
    dt
  }, server = FALSE)

  # Checkbox state change -> update required flag
  observeEvent(input$layout_checkbox_changed, {
    info <- input$layout_checkbox_changed
    idx  <- as.integer(info$row)
    if (!is.null(idx) && idx >= 1L && idx <= nrow(rv$layout)) {
      rv$layout$required[idx] <- isTRUE(info$checked)
    }
  })

  # Capture cell edits (display cols 0-4 map to rv$layout cols 1-5)
  observeEvent(input$layout_table_cell_edit, {
    info    <- input$layout_table_cell_edit
    col_idx <- info$col + 1L
    if (col_idx > 5L) return()   # ignore Required column
    rv$layout[info$row, col_idx] <- DT::coerceValue(
      info$value, rv$layout[info$row, col_idx])
    if (col_idx == 3L) rv$layout[info$row, 3L] <- tolower(rv$layout[info$row, 3L])
  })

  # Data preview -- grey out non-required columns
  output$data_preview <- renderDT({
    req(rv$raw_df, rv$layout)
    df <- head(rv$raw_df, 10)
    dt <- datatable(df,
      rownames  = FALSE,
      selection = "none",
      options   = list(dom = "t", scrollX = TRUE, pageLength = 10, ordering = FALSE)
    )
    not_required <- rv$layout$original_name[!rv$layout$required]
    cols_to_grey <- intersect(not_required, names(df))
    if (length(cols_to_grey) > 0) {
      dt <- formatStyle(dt, cols_to_grey,
        backgroundColor = "#ebebeb", color = "#aaaaaa")
    }
    dt
  })

  # Visibility flag
  output$file_loaded <- renderText({
    if (!is.null(rv$raw_df)) "yes" else ""
  })
  outputOptions(output, "file_loaded", suspendWhenHidden = FALSE)

  # Save all three layout files
  observeEvent(input$save_layout, {
    req(rv$layout)

    errors <- character(0)
    if (nchar(trimws(input$source_system)) == 0) {
      errors <- c(errors, "Source System is required.")
    } else if (!is_valid_id(input$source_system)) {
      errors <- c(errors, paste0("source_system '", input$source_system, "' is not a valid identifier (letters, digits, _ or . only; must not start with a digit)."))
    }
    if (nchar(trimws(input$account_id)) == 0) {
      errors <- c(errors, "Account ID is required.")
    } else if (!is_valid_id(input$account_id)) {
      errors <- c(errors, paste0("account_id '", input$account_id, "' is not a valid identifier (letters, digits, _ or . only; must not start with a digit)."))
    }
    if (nchar(trimws(input$layout_id)) == 0) {
      errors <- c(errors, "Layout ID is required.")
    } else if (!is_valid_id(input$layout_id)) {
      errors <- c(errors, paste0("layout_id '", input$layout_id, "' is not a valid identifier (letters, digits, _ or . only; must not start with a digit)."))
    }

    valid_to_val <- trimws(input$valid_to)
    if (nchar(valid_to_val) > 0) {
      d <- suppressWarnings(as.Date(valid_to_val, format = "%Y-%m-%d"))
      if (is.na(d)) errors <- c(errors, "valid_to must be YYYY-MM-DD or blank.")
    }

    out_dir <- trimws(input$output_dir)
    if (nchar(out_dir) == 0) errors <- c(errors, "Output directory is required.")

    if (length(errors) > 0) {
      output$save_msg <- renderUI({
        tags$div(class = "field-error",
          lapply(errors, function(msg) tags$div(msg)))
      })
      return()
    }

    if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

    ss  <- input$source_system
    ai  <- input$account_id
    lid <- input$layout_id
    vf  <- as.character(input$valid_from)
    vt  <- if (nchar(valid_to_val) > 0) valid_to_val else NA_character_

    result <- tryCatch({

      n_cols <- upsert_csv(
        file.path(out_dir, "layout_cols.csv"),
        data.frame(
          source_system    = ss,
          account_id       = ai,
          layout_id        = lid,
          column_position  = seq_len(nrow(rv$layout)),
          canonical_field  = rv$layout$intended_name,
          expected_pattern = rv$layout$format,
          required         = ifelse(rv$layout$required, "True", "False"),
          stringsAsFactors = FALSE
        ),
        key_cols = c("source_system", "account_id", "layout_id", "column_position")
      )

      n_layouts <- upsert_csv(
        file.path(out_dir, "layouts.csv"),
        data.frame(
          source_system     = ss,
          account_id        = ai,
          layout_id         = lid,
          layout_valid_from = vf,
          layout_valid_to   = vt,
          stringsAsFactors  = FALSE
        ),
        key_cols = c("source_system", "account_id", "layout_id")
      )

      n_accounts <- upsert_csv(
        file.path(out_dir, "accounts.csv"),
        data.frame(
          source_system = ss,
          account_id    = ai,
          account_label = trimws(input$account_label),
          account_type  = input$account_type,
          institution   = trimws(input$institution),
          stringsAsFactors = FALSE
        ),
        key_cols = c("source_system", "account_id")
      )

      list(ok = TRUE, n_cols = n_cols, n_layouts = n_layouts, n_accounts = n_accounts)
    }, error = function(e) {
      list(ok = FALSE, msg = e$message)
    })

    code_style <- "background:#e8f4fb; color:#1a6a9a; border:none; padding:2px 4px;"

    if (!result$ok) {
      output$save_msg <- renderUI({
        tags$div(class = "field-error", paste("Save failed:", result$msg))
      })
      return()
    }

    output$save_msg <- renderUI({
      tags$div(style = "color: #27ae60;",
        tags$strong("Files saved to:"),
        tags$br(),
        tags$code(style = code_style, out_dir),
        tags$ul(style = "margin-top:6px;",
          tags$li(tags$code(style = code_style, "layout_cols.csv"),
            sprintf(" — %d rows", result$n_cols)),
          tags$li(tags$code(style = code_style, "layouts.csv"),
            sprintf(" — %d rows", result$n_layouts)),
          tags$li(tags$code(style = code_style, "accounts.csv"),
            sprintf(" — %d rows", result$n_accounts))
        )
      )
    })
  })

  output$status_msg <- renderText({
    req(rv$layout)
    paste0(nrow(rv$layout), " columns loaded.")
  })
}

shinyApp(ui, server)
