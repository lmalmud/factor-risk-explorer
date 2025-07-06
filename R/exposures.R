# exposures.R
# Turn single=stock betas into portfolio-level factor
# exposures by weighting each stock's beta
# by its portoflio weight
# To run: docker compose run --rm r-model Rscript R/exposures.R

suppressPackageStartupMessages({
  library(dplyr) # for dataframe manipulation
  library(glue) # for string functions
  library(purrr) # for mapp_dfr
})

portfolio_exposures <- function(weights_df) {
  weights_df <- weights_df %>% mutate(date = as.Date(date))

  # all of the stocks that we will need to pull betas for
  tickers <- unique(weights_df$ticker)

  # map_dfr applies a function to each element of tickers
  # and each result (dataframe) is stacked into a single dataframe
  betas_all <- map_dfr(tickers, function(tkr) {
    # construct the path for the file that contains the regressed betas
    path <- here("output", tkr, glue("{tkr}_beta.rds"))

    # error if that file does not exist
    if (!file.exists(path)) {
      stop(glue("Missing beta file: {path}.
                Run ./run_pipeline.sh with this {tkr}"))
    }

    # return desired columns
    readRDS(path) %>%
      select(date, ends_with("_est")) %>%
      mutate(date = as.Date(date), ticker = tkr)
  })

  # identify all of the factor columsn we want to keep
  factor_cols <- grep("_est$", names(betas_all), value = TRUE)
  factor_cols <- setdiff(factor_cols, "(Intercept)_est")  # drop alpha

  exposures <- weights_df %>%
    # match by both weight and ticker
    inner_join(betas_all, by = c("date", "ticker")) %>%

    # beta * weight
    mutate(across(all_of(factor_cols), ~ .x * weight)) %>%
    group_by(date) %>%

    # sum factors across all securities per date
    summarize(across(all_of(factor_cols), sum), .groups = "drop") %>%

    # get rid of '_est' and replace with 'beta'
    rename_with(~ gsub("_est$", "_beta", .x), all_of(factor_cols))
}

# For debugging...
#library(here)
#source(here("R", "weights.R"), local = TRUE) # load_weights
#weights_df <- load_weights()
#print(portfolio_exposures(weights_df))