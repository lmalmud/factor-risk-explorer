# weights.R
# Get the portfolio weights from the portfolio_weights SQL database
# To run: docker compose run --rm r-model Rscript R/weights.R

source("R/data_access.R") # for get_db_connection
library(RPostgreSQL) # to interact with server
library(glue) # for safe SQL commands
library(dplyr) # for mutate

load_weights <- function(conn, as_of = "2025-07-08") {
  conn <- get_db_connection()

  # Only select rows with the appropriate date
  query <- glue::glue_sql("SELECT * FROM portfolio_weights
                          WHERE date = {as_of}",
                          .con = conn)

  # Enforce schema for date
  df <- dbGetQuery(conn, query) %>% mutate(date = as.Date(date))

}