# modeling.R
# Rolling Fama-French-5-plus-Momentum regression engine
# To run: docker compose run r-model Rscript R/modeling.R

# Rolling (windowed) regression fits the same
# linear model repeatedly on a sliding, fixed-length window
# of observations ordered in time
# Our window size is 252 trading days = 1 year

suppressPackageStartupMessages({
  library(zoo) # rollapply() - rolling window operations
  library(broom) # tidy(), glance()
  library(dplyr) # data manipulation
  library(tidyr) # unnest_longer()
  library(here) # for file paths
  library(glue) # for making strings
  library(purrr) # for compact()
})

temp = TRUE

# Run rolling 6-factor regression for a single ticker
#
# @param df A tibble with columns:
#           date, excess_ret, MKT, SMB, HML, RMW, CMA, MOM
# @param window Size of the rolling window in trading days (default 252)
# @return A tidy tibble of coefficients, alpha, R^2, RMSE, indexed by window_end
run_rolling_ff6 <- function(df, window = 252) {

  # Ensure sorted by date and complete cases
  # Sorts by date and removes any rows with missing values
  df <- df %>%
    arrange(date) %>%
    drop_na() %>%
    select(date, rtexcess, mkt_rf, smb, hml, rmw, cma, mom) %>%
    mutate(across(-date, as.numeric))

  # rollapply returns a list usually, but in this case
  # some returned items will be NULL
  
    roll_zoo <- zoo::rollapplyr(
    data      = df,
    width     = window,
    by.column = FALSE,
    align     = "right",
    FUN = function(sl) {

       sl <- as.data.frame(sl)

      # safety filters ----------------------------------------------------
      if (nrow(sl) < 10 ||
          sd(sl[["rtexcess"]]) == 0 ||
          any(vapply(sl[, -1], sd, numeric(1)) == 0))   # any constant predictor
        return(NULL)

      mod <- lm(rtexcess ~ mkt_rf + smb + hml + rmw + cma + mom, data = sl)

      tibble::tibble(
        window_end = max(sl[["date"]]),
        coefs      = list(broom::tidy(mod)[, c("term","estimate","std.error")]),
        stats      = list(broom::glance(mod)[, c("r.squared","adj.r.squared","sigma")])
      )
    }
  )

  roll_zoo |>
    as.list() |>
    purrr::keep(~ inherits(.x, "data.frame")) |>
    dplyr::bind_rows()                         # <— three columns: window_end, coefs, stats
}
  

get_model_data <- function(ticker) {
  input_path <- here('output', ticker, paste0(ticker, '_merged.rds'))
  if (!file.exists(input_path)) {
    stop(glue("Cannot find {input_path}. Run data_access.R first."))
  }
  merged_df <- readRDS(input_path)  # whatever path you use
  merged_df <- as.data.frame(merged_df)
  beta_ts   <- run_rolling_ff6(merged_df, window=100)
  print(head(beta_ts))
  print('names')
  print(names(beta_ts))
  print('7x3 expected')
  saveRDS(beta_ts, here('output', ticker, glue('{ticker}_beta.rds')))
}

# ----------------------------------------------------------------
# Example (comment out in production):
get_model_data('AMZN')