# modeling.R
# Rolling Fama-French-5-plus-Momentum regression engine

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
  print(df)

  # rollapply returns a list; convert each element to a data frame
  roll_list <- rollapplyr(
    data        = df,
    width       = window,
    by.column   = FALSE,
    align       = "right",
    FUN = function(slice) {
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
        print(out)
        out
    }
    # FUN         = function(slice) { # for each window slice...
    #   mod <- lm(excess_ret ~ MKT + SMB + HML + RMW + CMA + MOM,
    #             data = slice)
    #   # fits a linear model of excess returns on the six factors

    #   # Coefficients (long) + window metadata
    #   coef_tbl  <- tidy(mod) %>%
    #     select(term, estimate, std.error)
    #   # broom::tidy(mod) will extract model coefficients
    #   # only keep the term, estimate, and standard error

    #   # Model-level stats
    #   glance_tbl <- glance(mod) %>%
    #     select(r.squared, adj.r.squared, sigma)
    #   # broom::glance() will get the model-level statistics
    #   # and keeps r^2, adjusted r^2, and sigma

    #   # returns tibble for each window
    #   tibble(
    #     window_end = max(slice$date), # last date in the window
    #     coefs      = list(coef_tbl), # coefficients table (as list-column)
    #     stats      = list(glance_tbl) # model stats (as list-column)
    #   )
    # }
  )

  # combines all window results into a single dataframe
  # unnest the nested columns so everything is long & tidy
  # unest_longer will espand list-columns so each statistic is in its
  # own column
  roll_df <- roll_list %>%
    bind_rows() %>%
    unnest_longer(coefs) %>%         # brings term/estimate/std.error up
    unnest_longer(stats)             # brings r.squared, etc. up
  # implicit return
}

# ----------------------------------------------------------------
# Example (comment out in production):
merged_df <- readRDS("output/merged_MSFT.rds")  # whatever path you use
beta_ts   <- run_rolling_ff6(merged_df)
head(beta_ts)
