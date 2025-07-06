# risk.R
# To run: docker compose run --rm r-model Rscript R/risk.R
# VaR = value at risk
# single number that represents the maximum potential loss for a
# portfolio over a specific time horizon at a given CI
# ES = expected shortfall
# expected loss given that loss exceeds VaR threshold
# i.e. you fall into the \alpha tail

suppressPackageStartupMessages({
  library(here)
  library(stats)
})

calc_portfolio_var_est <- function(factor_returns,
                                   exposures_row,
                                   conf = .95) {

  # the names expected from the factors_daily database
  factor_cols <- grep("^(mkt_rf|smb|hml|rmw|cma|mom)$",
                      names(factor_returns), value = TRUE)
  # convert into appropriate names from the rolling regression
  beta_cols <- paste0(factor_cols, "_beta")

  # make numeric objects
  F_t <- factor_returns[, factor_cols] # Tx6
  beta_vec <- as.numeric(exposures_row[, beta_cols]) # 1x6

  # covariance matrix of daily factor returns
  Sigma_F <- cov(F_t, use = "pairwise.complete.obs") # 6x6

  # portfolio return variance implied by factor model
  sigma_p2 <- t(beta_vec) %*% Sigma_F %*% beta_vec # scalar
  sigma_p <- sqrt(sigma_p2)

  # VaR & ES
  z_alpha <- qnorm(1-conf) # negative
  var_p <- z_alpha * sigma_p
  es_p <- dnorm(z_alpha) / (1-conf) * sigma_p

  # tidy output
  data.frame(date = exposures_row$date,
             confidence = conf,
             var_1d = var_p,
             es_1d = es_p)
}

# To test:
#source(here("R", "factors.R"), local = TRUE) # load_factors()
#factors_df <- load_factors()
#exposures_df <- readRDS(here("output", "portfolio_exposures.rds"))
#print(calc_portfolio_var_est(factors_df, exposures_df))