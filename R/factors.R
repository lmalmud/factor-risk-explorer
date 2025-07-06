# factors.R
# To get the Fama French factors from SQL server.
# To run: docker compose run --rm r-model Rscript R/factors.R

suppressPackageStartupMessages({
  library(here)
  library(RPostgreSQL)
  library(dplyr)
})

source(here("R", "data_access.R"), local = TRUE) # get_db_connection

load_factors <- function() {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))
  query <- glue::glue_sql("SELECT * FROM factors_daily",
                        .con = conn)

  df <- dbGetQuery(conn, query) %>% mutate(date = as.Date(date))
}
