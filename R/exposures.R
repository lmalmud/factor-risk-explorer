# exposures.R
# To run: docker compose run --rm r-model Rscript R/exposures.R



portfolio_exposures <- function(weights_df, betas_df) {
  print(head(weights_df))
  print(head(betas_df))
  print(colnames(betas_df))
}

# For debugging...
library(here)
tkr <- "AMZN"
source(here("R", "weights.R"), local = TRUE) # load_weights
weights_df <- load_weights()
betas_df <- readRDS(here("output", tkr, glue("{tkr}_beta.rds")))
portfolio_exposures(weights_df, betas_df)