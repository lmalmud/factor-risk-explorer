# modeling.R
# Rolling Fama-French-5-plus-Momentum regression engine
# To run: docker compose run r-model Rscript R/modeling.R

# Rolling (windowed) regression fits the same
# linear model repeatedly on a sliding, fixed-length window
# of observations ordered in time
# Our window size is 252 trading days = 1 year

library(zoo) # rollapply() - rolling window operations
library(broom) # tidy(), glance()
library(dplyr) # data manipulation
library(tidyr) # unnest_longer()
library(here) # for file paths
library(glue) # for making strings
library(purrr) # for compact()

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
    drop_na()

  # rollapply returns a list usually, but in this case
  # some returned items will be NULL
  roll_zoo <- rollapplyr(
    data        = df,
    width       = window,

    # if true, the function is applied to each column separately
    by.column   = FALSE,
    align       = "right",
    FUN = function(slice) {
      slice <- as.data.frame(slice)

      # skip tiny or flat windows
      if (nrow(slice) < 10 || sd(slice$rtexcess) == 0) {
        return(NULL)                # rollapply will store NA for this slot
      }

      mod <- lm(rtexcess ~ mkt_rf + smb + hml + rmw + cma + mom, data = slice)

      tibble(
        window_end = max(slice$date),
        coefs      = list(broom::tidy(mod)[, c("term","estimate","std.error")]),
        stats      = list(broom::glance(mod)[, c("r.squared","adj.r.squared","sigma")])
      )

    }

  )

  

  roll_df <- roll_zoo |>
    as.list() |>                               # turn zoo into plain list
    purrr::keep(~ inherits(.x, "data.frame")) |>  # drop the NA placeholders
    dplyr::bind_rows()                      # combine rows

    message("----- STRUCTURE OF roll_df =====")
print(str(roll_df, max.level = 1))
    return(roll_df)


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
  print(beta_ts[[1]]$coefs[[1]])
  saveRDS(beta_ts, here('output', ticker, glue('{ticker}_beta.rds')))
}

# ----------------------------------------------------------------
# Example (comment out in production):
get_model_data('AMZN')