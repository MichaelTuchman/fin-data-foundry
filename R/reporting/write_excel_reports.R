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

#  a1 |> head(5)
#                 account_label     y     m sgn_amt  sum_amt     N
#                        <char> <int> <int>   <num>    <num> <int>
# 1: American Express Gold Card  2019     1      -1  -411.83    14
# 2: American Express Gold Card  2019     1       1   265.38     2
# 3: American Express Gold Card  2019     2      -1 -1109.84    19
# 4: American Express Gold Card  2019     2       1   447.20     2
# 5: American Express Gold Card  2019     3      -1 -1786.18    25
# > 
#   


a1 |> dcast.data.table(account_label + y + m  ~ sgn_amt, fun.aggregate = sum, value.var = "sum_amt")

a1[, dir := fifelse(sgn_amt < 0, "expense_or_debit", "income_or_credit")]

wide_table = a1 |> dcast.data.table(account_label +y + m~ dir, fun.aggregate = sum, value.var = "sum_amt")
wide_table[,net:=expense_or_debit + income_or_credit]

format_dollars <- function(dt, cols = names(dt)[-(1:3)]) {
  copy(dt)[, (cols) := lapply(.SD, scales::dollar, accuracy = 0.01),
           .SDcols = cols][]
}

format_dollars(wide_table)


