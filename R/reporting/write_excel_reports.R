library(openxlsx)

wb <- createWorkbook()

addWorksheet(wb, "Post Flight Charges")

writeData(
  wb,
  sheet = "Post Flight Charges",
  x = dt
)

saveWorkbook(
  wb,
  "c:\\Users/mftuc/Downloads/postflight2.xslx",
  overwrite = TRUE
)
