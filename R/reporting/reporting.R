# =====================================================================
# run sql query in athena
# =====================================================================

run_athena_select <- function(query,connection=con3) {
  DBI::dbGetQuery(conn=connection,query)
}


