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
# Filename parser: impute source_system, account_id, valid_from from name
#   aaa_bbb_yyyymmdd
#   aaa_bbb_yyyymm_yyyymm
# Returns a list or NULL if pattern not matched.
# --------------------------------------------------------------------------
parse_filename <- function(filename) {
  base <- tools::file_path_sans_ext(basename(filename))

  # Pattern 1: aaa_bbb_yyyymmdd
  m <- regmatches(base, regexec("^([^_]+)_([^_]+)_([0-9]{8})$", base))[[1]]
  if (length(m) == 4) {
    d <- suppressWarnings(as.Date(m[4], format = "%Y%m%d"))
    if (!is.na(d)) return(list(source_system = m[2], account_id = m[3], valid_from = d))
  }

  # Pattern 2: aaa_bbb_yyyymm_yyyymm
  m <- regmatches(base, regexec("^([^_]+)_([^_]+)_([0-9]{6})_([0-9]{6})$", base))[[1]]
  if (length(m) == 5) {
    d <- suppressWarnings(as.Date(paste0(m[4], "01"), format = "%Y%m%d"))
    if (!is.na(d)) return(list(source_system = m[2], account_id = m[3], valid_from = d))
  }

  NULL
}

# --------------------------------------------------------------------------
# Inference helpers
# --------------------------------------------------------------------------

infer_type <- function(x) {
  x_clean <- x[!is.na(x) & trimws(x) != ""]
  if (length(x_clean) == 0) return("char")
  num_attempt <- suppressWarnings(as.numeric(gsub("[,$%()\\ ]", "", x_clean)))
  if (mean(!is.na(num_attempt)) >= 0.80) "numeric" else "char"
}

DATE_SPECS <- list(
  list(regexp = "^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$",         fmt = "%m/%d/%Y"),
  list(regexp = "^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}$",          fmt = "%m/%d/%y"),
  list(regexp = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",              fmt = "%Y-%m-%d"),
  list(regexp = "^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{4}$",         fmt = "%d-%b-%Y"),
  list(regexp = "^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$",         fmt = "%d-%b-%y"),
  list(regexp = "^[A-Za-z]{3}\\s+[0-9]{1,2},?\\s+[0-9]{4}$", fmt = "%b %d, %Y")
)

MONETARY_REGEXP <- "^-?\\$?[0-9,]+(\\.[0-9]{2})?$"
NUMERIC_REGEXP  <- "^-?[0-9]+(\\.[0-9]+)?$"
CHAR_REGEXP     <- ".*"

infer_usage_and_format <- function(x, type) {
  if (type != "numeric") return(list(usage = "", format = CHAR_REGEXP))
  x_clean <- x[!is.na(x) & trimws(x) != ""]
  if (length(x_clean) == 0) return(list(usage = "numeric", format = NUMERIC_REGEXP))

  for (ds in DATE_SPECS) {
    if (mean(grepl(ds$regexp, x_clean)) >= 0.70) {
      return(list(usage = "date", format = ds$fmt))
    }
  }

  monetary_hits <- mean(grepl("[$,()-]", x_clean))
  if (!is.nan(monetary_hits) && monetary_hits >= 0.30) {
    return(list(usage = "monetary", format = MONETARY_REGEXP))
  }

  list(usage = "numeric", format = NUMERIC_REGEXP)
}

infer_column_name <- function(raw_name) {
  nm <- trimws(raw_name)
  nm <- gsub("[^A-Za-z0-9 ]", " ", nm)
  nm <- trimws(gsub("\\s+", "_", nm))
  nm
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
    col_type <- infer_type(col_data)
    uf       <- infer_usage_and_format(col_data, col_type)
    data.frame(
      original_name = raw_names[i],
      intended_name = infer_column_name(raw_names[i]),
      type          = col_type,
      usage         = uf$usage,
      format        = uf$format,
      description   = "",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

# --------------------------------------------------------------------------
# File helpers: append rows and deduplicate on key columns
# --------------------------------------------------------------------------

upsert_csv <- function(filepath, new_rows, key_cols) {
  if (file.exists(filepath)) {
    existing <- tryCatch(
      read.csv(filepath, stringsAsFactors = FALSE, check.names = FALSE),
      error = function(e) new_rows[0, ]
    )
    for (col in setdiff(names(new_rows), names(existing))) existing[[col]] <- NA
    for (col in setdiff(names(existing), names(new_rows))) new_rows[[col]] <- NA
    existing <- existing[, names(new_rows), drop = FALSE]
    combined <- rbind(existing, new_rows)
    key_vals <- do.call(paste, c(combined[, key_cols, drop = FALSE], sep = "||"))
    combined <- combined[!duplicated(key_vals, fromLast = TRUE), ]
  } else {
    combined <- new_rows
  }
  write.csv(combined, file = filepath, row.names = FALSE, quote = TRUE)
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

  titlePanel("Metadata Editor"),

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
      hr(),

      h3("2. Account Metadata"),
      selectInput("account_type", "Account Type",
        choices = c("(select)" = "", "Checking" = "Checking", "Credit Card" = "Credit Card")
      ),
      textInput("account_id", "Account ID",
        placeholder = "e.g. Chase_Checking_1234"
      ),
      uiOutput("account_id_msg"),
      hr(),

      h3("3. Save Layout"),
      textInput("source_system", "Source System",
        placeholder = "e.g. Chase_Bank"
      ),
      uiOutput("source_system_msg"),
      textInput("layout_id", "Layout ID",
        placeholder = "e.g. chase_checking_v1"
      ),
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
          h3("Column Layout -- edit any cell directly"),
          helpText(
            "Type: char or numeric  |  ",
            "Usage (numeric only): monetary, date, or numeric  |  ",
            "Format: lubridate string for dates, regexp for others  |  ",
            "Intended Name and Description are free-text."
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
            tableOutput("data_preview")
          )
        )
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

  # Load CSV and impute fields from filename
  observeEvent(input$csv_file, {
    req(input$csv_file)
    tryCatch({
      df <- read.csv(
        input$csv_file$datapath,
        header           = input$has_header,
        sep              = input$delimiter,
        stringsAsFactors = FALSE,
        check.names      = FALSE
      )
      colnames(df) <- fix_colnames(colnames(df))
      rv$raw_df    <- df
      rv$raw_names <- colnames(df)
      rv$layout    <- build_layout(df, colnames(df))

      # Impute metadata fields from filename
      parsed <- parse_filename(input$csv_file$name)
      if (!is.null(parsed)) {
        updateTextInput(session,  "source_system", value = parsed$source_system)
        updateTextInput(session,  "account_id",    value = parsed$account_id)
        updateDateInput(session,  "valid_from",    value = parsed$valid_from)
      }
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

  # Editable layout table
  output$layout_table <- renderDT({
    req(rv$layout)
    display <- rv$layout
    names(display) <- c("Original Name", "Intended Name", "Type", "Usage", "Format", "Description")
    dt <- datatable(
      display,
      rownames  = FALSE,
      editable  = list(target = "cell", disable = list(columns = 0)),
      selection = "none",
      options   = list(
        pageLength = 25,
        dom        = "tp",
        columnDefs = list(
          list(width = "140px", targets = 0),
          list(width = "140px", targets = 1),
          list(width = "80px",  targets = 2),
          list(width = "90px",  targets = 3),
          list(width = "190px", targets = 4),
          list(width = "190px", targets = 5)
        )
      )
    )
    dt <- formatStyle(dt, "Type",
      backgroundColor = styleEqual(c("char", "numeric"), c("#eaf4fb", "#eafaf1")))
    dt <- formatStyle(dt, "Usage",
      color = styleEqual(c("monetary", "date"), c("#8e44ad", "#c0392b")))
    dt
  }, server = TRUE)

  # Capture edits
  observeEvent(input$layout_table_cell_edit, {
    info    <- input$layout_table_cell_edit
    col_idx <- info$col + 1L
    rv$layout[info$row, col_idx] <- DT::coerceValue(
      info$value, rv$layout[info$row, col_idx])
    if (col_idx == 3L) rv$layout[info$row, 3L] <- tolower(rv$layout[info$row, 3L])
    if (col_idx == 4L) rv$layout[info$row, 4L] <- tolower(rv$layout[info$row, 4L])
  })

  # Data preview
  output$data_preview <- renderTable({
    req(rv$raw_df)
    head(rv$raw_df, 10)
  }, striped = TRUE, hover = TRUE, bordered = TRUE, na = "")

  # Visibility flag
  output$file_loaded <- renderText({
    if (!is.null(rv$raw_df)) "yes" else ""
  })
  outputOptions(output, "file_loaded", suspendWhenHidden = FALSE)

  # Save all three layout files
  observeEvent(input$save_layout, {
    req(rv$layout)

    errors <- character(0)
    if (!is_valid_id(input$source_system)) errors <- c(errors, "source_system is not a valid identifier.")
    if (!is_valid_id(input$account_id))   errors <- c(errors, "account_id is not a valid identifier.")
    if (!is_valid_id(input$layout_id))    errors <- c(errors, "layout_id is not a valid identifier.")

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

    # layout_cols.csv
    upsert_csv(
      file.path(out_dir, "layout_cols.csv"),
      data.frame(
        source_system = ss,
        account_id    = ai,
        layout_id     = lid,
        column_number = seq_len(nrow(rv$layout)),
        column_type   = rv$layout$type,
        usage_type    = rv$layout$usage,
        format        = rv$layout$format,
        original_name = rv$layout$original_name,
        intended_name = rv$layout$intended_name,
        description   = rv$layout$description,
        stringsAsFactors = FALSE
      ),
      key_cols = c("source_system", "account_id", "layout_id", "column_number")
    )

    # layout.csv
    upsert_csv(
      file.path(out_dir, "layout.csv"),
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

    # account.csv
    upsert_csv(
      file.path(out_dir, "account.csv"),
      data.frame(
        source_id    = ss,
        account_id   = ai,
        account_type = input$account_type,
        stringsAsFactors = FALSE
      ),
      key_cols = c("source_id", "account_id")
    )

    output$save_msg <- renderUI({
      tags$div(style = "color: #27ae60; font-weight: bold;",
        paste0("Saved to ", out_dir))
    })
  })

  output$status_msg <- renderText({
    req(rv$layout)
    paste0(nrow(rv$layout), " columns loaded.")
  })
}

shinyApp(ui, server)
