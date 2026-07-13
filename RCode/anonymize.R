anonymize_transactions <- function(
    DT,
    text_columns = "description",
    replacements = NULL
) {
  
  stopifnot(data.table::is.data.table(DT))
  
  out <- data.table::copy(DT)
  
  anonymize_text <- function(x) {
    
    x <- stringr::str_to_upper(x)
    
    if (!is.null(replacements)) {
      
      stopifnot(
        all(c("pattern", "replacement") %in% names(replacements))
      )
      
      replacements$pattern <- stringr::str_to_upper(replacements$pattern)
      
      for (i in seq_len(nrow(replacements))) {
        x <- stringr::str_replace_all(
          x,
          stringr::fixed(replacements$pattern[i]),
          replacements$replacement[i]
        )
      }
    }
    
    x |>
      stringr::str_replace_all(
        "\\b\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}\\b",
        "<DATE>"
      ) |>
      stringr::str_replace_all(
        "\\b\\d{6}\\b",
        "<DATECODE>"
      ) |>
      stringr::str_replace_all(
        "\\b[xX*]{3,}\\d{2,6}\\b",
        "<ACCOUNT>"
      ) |>
      stringr::str_replace_all(
        "\\b\\d{8,}\\b",
        "<ID>"
      ) |>
      stringr::str_replace_all(
        "\\b[A-Z]\\d{3,6}\\b",
        "<ID>"
      ) |>
      stringr::str_replace_all(
        "\\b\\d{3}-\\d{3}-\\d{4}\\b",
        "<PHONE>"
      ) |>
      stringr::str_replace_all(
        "\\b\\(?\\d{3}\\)?[- ]?\\d{3}[- ]?\\d{4}\\b",
        "<PHONE>"
      ) |>
      stringr::str_squish()
  }
  
  out[, (text_columns) := lapply(.SD, anonymize_text), .SDcols = text_columns]
  
  out
}

personal_replacements <- data.table::data.table(
  pattern = c(
    "M KNOWLES TUCHMAN",
    "MICHAEL TUCHMAN",
    "CARD 1159"
  ),
  replacement = c(
    "<SEXY_WIFE>",
    "<HUSBAND>",
    "<SEXY_WIFE>"
  )
)

X=anonymize_transactions(
  DT,
  text_columns = "description",
  replacements = personal_replacements
) |>
  anonymize_transactions(
    text_columns = "source_description",
    replacements = personal_replacements
  )

run_athena_select("select * from metadata_transaction_type_rules")

run_athena_select("
SELECT DISTINCT
transaction_type
FROM metadata_transaction_type_rules
ORDER BY 1;")
