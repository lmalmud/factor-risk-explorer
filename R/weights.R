# weights.R
# Get the portfolio weights from the portfolio_weights SQL database
# To run: docker compose run --rm r-model Rscript R/weights.R

suppressPackageStartupMessages({
  library(RPostgreSQL) # to interact with server
  library(glue) # for safe SQL commands
  library(dplyr) # for mutate
  library(here)
})

source(here("R", "data_access.R"), local = TRUE)


load_weights <- function(as_of = "2025-07-08") {
  conn <- get_db_connection()

  # Only select rows with the appropriate date
  query <- glue::glue_sql("SELECT * FROM portfolio_weights
                          WHERE date = {as_of}",
                          .con = conn)

  # Enforce schema for date
  df <- dbGetQuery(conn, query) %>% mutate(date = as.Date(date))

}