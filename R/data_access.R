# data_access.R
# Functions to download data from SQL data for a particular ticker.
library(DBI) # Import in order to connect to SQL data for dbConnect
library(RPostgreSQL) # for RMYSQL::MySQL

dbGetQuery <- function(ticker) {
  drv <- dbDriver("PostgreSQL") # Need a driver that is PostgreSQL
  conn <- dbConnect(drv,
                   dbname = "factor_data",
                   host = "db",
                   port = 5432,
                   user = "postgres",
                   password = "postgres");
  query <- sprintf("FROM vw_returns SELECT * WHERE ticker = %s;", ticker);
  result <- dbGetQuery(conn, query);
  print(result)
}

dbGetQuery('MSFT')

# to ensure that bind-mount working: docker-compose exec r-model ls /app/R
# to build: docker compose build
# docker compose run r-model