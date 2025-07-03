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
  print(typeof(df))

  # rollapply returns a list; convert each element to a data frame
  roll_list <- rollapplyr(
    data        = df,
    width       = window,
    by.column   = FALSE,
    align       = "right",
    FUN = function(slice) {
      slice <- as.data.frame(slice)

      # output things that may be resulting in NaN
      if (nrow(slice) <= 7) return(NULL)
      if (sd(slice$rtexcess) == 0) return(NULL)

      # if there are no values in the slice, skip it
      if (nrow(slice) == 0) {
        print("Empty slice!")
        return(NULL)
      }

      mod <- lm(rtexcess ~ mkt_rf + smb + hml + rmw + cma + mom, data = slice)
      coef_tbl  <- tidy(mod) %>% select(term, estimate, std.error)
      glance_tbl <- glance(mod) %>% select(r.squared, adj.r.squared, sigma)
      out <- tibble(
        window_end = max(slice$date),
        coefs      = list(coef_tbl),
        stats      = list(glance_tbl)
      )
    
      # display the current stats to the screen
      print(out)
    }

  )

  # combines all window results into a single dataframe
  # unnest the nested columns so everything is long & tidy
  # unest_longer will espand list-columns so each statistic is in its
  # own column
  roll_list <- as.data.frame(roll_list)
  roll_df <- roll_list %>%
    bind_rows() %>%
    unnest_longer(coefs) %>%         # brings term/estimate/std.error up
    unnest_longer(stats)             # brings r.squared, etc. up
  # implicit return
}

# ----------------------------------------------------------------
# Example (comment out in production):
merged_df <- readRDS("output/merged_MSFT.rds")  # whatever path you use
merged_df <- as.data.frame(merged_df)
beta_ts   <- run_rolling_ff6(merged_df)
head(beta_ts)
saveRDS(beta_ts, 'beta_ts_test.rds')
