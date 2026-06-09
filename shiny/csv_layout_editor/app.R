library(shiny)
library(DT)
library(readr)
library(lubridate)

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && nchar(a) > 0) a else b

# --------------------------------------------------------------------------
# Inference helpers
# --------------------------------------------------------------------------

infer_type <- function(x) {
  x_clean <- x[!is.na(x) & trimws(x) != ""]
  if (length(x_clean) == 0) return("char")
  num_attempt <- suppressWarnings(as.numeric(gsub("[,$%()\\ ]", "", x_clean)))
  if (mean(!is.na(num_attempt)) >= 0.80) "numeric" else "char"
}

infer_usage <- function(x, type) {
  if (type != "numeric") return("")
  x_clean <- x[!is.na(x) & trimws(x) != ""]
  if (length(x_clean) == 0) return("numeric")

  date_patterns <- c(
    "^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}$",
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
    "^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2,4}$",
    "^[A-Za-z]{3}\\s+[0-9]{1,2},?\\s+[0-9]{4}$"
  )

  hit_rate <- function(pattern) mean(grepl(pattern, x_clean))
  date_hits <- vapply(date_patterns, hit_rate, numeric(1))

  if (max(date_hits, na.rm = TRUE) >= 0.70) return("date")

  monetary_hits <- mean(grepl("[$,()-]", x_clean))
  if (!is.nan(monetary_hits) && monetary_hits >= 0.30) return("monetary")

  "numeric"
}

infer_column_name <- function(raw_name) {
  nm <- trimws(raw_name)
  nm <- gsub("[^A-Za-z0-9 ]", " ", nm)
  nm <- trimws(gsub("\\s+", "_", nm))
  nm
}

build_layout <- function(df, raw_names) {
  rows <- lapply(seq_along(raw_names), function(i) {
    col_data <- as.character(df[[i]])
    col_type <- infer_type(col_data)
    col_usage <- infer_usage(col_data, col_type)
    data.frame(
      original_name = raw_names[i],
      intended_name = infer_column_name(raw_names[i]),
      type          = col_type,
      usage         = col_usage,
      description   = "",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
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
      "#status_msg { font-weight: bold; margin-top: 8px; }"
    )))
  ),

  titlePanel("CSV Layout Editor"),

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
      textInput("account_type", "Account Type",
        placeholder = "e.g. Checking, Credit Card, Brokerage"
      ),
      selectInput("bank_account_type", "Bank Account Type",
        choices = c("(select)" = "", "Asset" = "Asset", "Liability" = "Liability")
      ),
      dateInput("valid_from", "Layout Valid From",
        value  = Sys.Date(),
        format = "yyyy-mm-dd"
      ),
      hr(),

      h3("3. Save Layout"),
      downloadButton("save_layout", "Save Layout as CSV", class = "btn-success"),
      br(), br(),
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

  # Load CSV file
  observeEvent(input$csv_file, {
    req(input$csv_file)
    tryCatch({
      df <- read.csv(
        input$csv_file$datapath,
        header          = input$has_header,
        sep             = input$delimiter,
        stringsAsFactors = FALSE,
        check.names     = FALSE
      )
      rv$raw_df    <- df
      rv$raw_names <- colnames(df)
      rv$layout    <- build_layout(df, colnames(df))
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message),
        type = "error", duration = 8)
    })
  })

  # Reset layout to inferred values
  observeEvent(input$reset_inference, {
    req(rv$raw_df)
    rv$layout <- build_layout(rv$raw_df, rv$raw_names)
    showNotification("Layout reset to inferred values.", type = "message")
  })

  # Render editable layout table
  output$layout_table <- renderDT({
    req(rv$layout)
    dt <- datatable(
      rv$layout,
      rownames  = FALSE,
      editable  = list(target = "cell", disable = list(columns = 0)),
      selection = "none",
      colnames  = c("Original Name", "Intended Name", "Type", "Usage", "Description"),
      options   = list(
        pageLength = 25,
        dom        = "tp",
        columnDefs = list(
          list(width = "160px", targets = 0),
          list(width = "160px", targets = 1),
          list(width = "90px",  targets = 2),
          list(width = "100px", targets = 3),
          list(width = "300px", targets = 4)
        )
      )
    )
    dt <- formatStyle(dt, "type",
      backgroundColor = styleEqual(
        c("char", "numeric"), c("#eaf4fb", "#eafaf1")
      )
    )
    dt <- formatStyle(dt, "usage",
      color = styleEqual(
        c("monetary", "date"), c("#8e44ad", "#c0392b")
      )
    )
    dt
  }, server = TRUE)

  # Capture inline cell edits
  observeEvent(input$layout_table_cell_edit, {
    info    <- input$layout_table_cell_edit
    col_idx <- info$col + 1L
    rv$layout[info$row, col_idx] <- DT::coerceValue(
      info$value, rv$layout[info$row, col_idx]
    )
    if (col_idx == 3L) {
      rv$layout[info$row, 3L] <- tolower(rv$layout[info$row, 3L])
    }
    if (col_idx == 4L) {
      rv$layout[info$row, 4L] <- tolower(rv$layout[info$row, 4L])
    }
  })

  # Data preview
  output$data_preview <- renderTable({
    req(rv$raw_df)
    head(rv$raw_df, 10)
  }, striped = TRUE, hover = TRUE, bordered = TRUE, na = "")

  # Output flag used by conditionalPanel
  output$file_loaded <- renderText({
    if (!is.null(rv$raw_df)) "yes" else ""
  })
  outputOptions(output, "file_loaded", suspendWhenHidden = FALSE)

  # Save layout as CSV
  output$save_layout <- downloadHandler(
    filename = function() {
      base <- tools::file_path_sans_ext(
        basename(input$csv_file$name %||% "layout")
      )
      paste0(base, "_layout_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(con) {
      req(rv$layout)
      meta_lines <- c(
        "# METADATA",
        paste0("# account_type: ",      input$account_type),
        paste0("# bank_account_type: ", input$bank_account_type),
        paste0("# valid_from: ",        as.character(input$valid_from)),
        "#"
      )
      writeLines(meta_lines, con)
      write.table(
        rv$layout,
        file      = con,
        append    = TRUE,
        sep       = ",",
        row.names = FALSE,
        col.names = TRUE,
        qmethod   = "double"
      )
    }
  )

  output$status_msg <- renderText({
    req(rv$layout)
    paste0(nrow(rv$layout), " columns loaded.")
  })
}

shinyApp(ui, server)
