# data_access.R
# Functions to download data from SQL data for a particular ticker.
# To run: docker compose run r-model Rscript R/data_access.R

suppressPackageStartupMessages({
  library(RPostgreSQL) # For creating the driver
  # Interface to PostgreSQL databases in R

  library(glue) # For safe connections
  # Use glue_sql() to avoid SQL injection

  library(dplyr) # For database manipulations
  library(here)
})


# Creates and returns a connection to the PostgreSQL database
get_db_connection <- function() {
  dbConnect(RPostgreSQL::PostgreSQL(), # Driver
            dbname = "factor_data",
            host = "db",
            port = 5432,
            user = "postgres",
            password = "postgres")
}

# Retrieves and returns data for a given ticker
get_returns_data <- function(conn, ticker) {
  # Construct parametrized SQL query
  query <- glue::glue_sql(
                          "SELECT * FROM vw_returns WHERE ticker = {ticker}",
                          .con = conn)
  # Stores query result in df
  df <- dbGetQuery(conn, query) %>%
    mutate(date = as.Date(date))
}

# Pull all factor data
get_factor_data <- function(conn) {
  query <- "SELECT * FROM factors_daily"
  df <- dbGetQuery(conn, query)
  df <- df %>% mutate(date = as.Date(date))
  return(df)
}

# Main function to pull and join
get_merged_data <- function(ticker) {
  conn <- get_db_connection()
  on.exit(dbDisconnect(conn))  # ensure disconnection on exit

  returns <- get_returns_data(conn, ticker)
  factors <- get_factor_data(conn)

  # Join on date
  merged <- left_join(returns, factors, by = "date") %>%
    mutate(across(-c(date, ticker), as.numeric)) %>%
    mutate(rtexcess = log_ret - rf) %>%
    arrange(date)

  # log returns anad risk-free rate are both expressed as per-period rates
  # they are both in decimal format
  # log returns approximate the continously compounted return for that period

  source(here::here("R", "util_paths.R"))  # to import make_path
  output_dir <- dirname(make_path(ticker, "merged", "rds"))
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  saveRDS(merged, make_path(ticker, "merged", "rds"))
}

#get_merged_data("MSFT")