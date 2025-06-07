# data_access.R
# Functions to download data from SQL data for a particular ticker.

library(RPostgres) # For creating the driver
library(glue) # For safe connections (https://glue.tidyverse.org/reference/glue_sql.html#:~:text=glue_sql.Rd,DBI%3A%3ASQL()%20objects.)

get_db_connection <- function() {
  dbConnect(RPostgres::Postgres(), # Driver
            dbname = "factor_data",
            host = "db",
            port = 5432,
            user = "postgres",
            password = "postgres");
}

get_returns_data <- function(conn, ticker) {
  query <- glue::glue_sql("SELECT * FROM vw_returns WHERE ticker = {ticker}", .con = conn)
  df <- dbGetQuery(conn, query)
}

dbGetQuery <- function(ticker) {
  drv <- dbDriver("PostgreSQL") # Need a driver that is PostgreSQL
  conn <- dbConnect(drv,
                   dbname = "factor_data",
                   host = "db",
                   port = 5432,
                   user = "postgres",
                   password = "postgres");
  query <- sprintf("SELECT * FROM vw_returns WHERE ticker = '%s'", ticker);
  result <- RPostgreSQL::dbGetQuery(conn, query);
  print(result)
}

dbGetQuery('MSFT')