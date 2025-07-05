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
    select(date, rtexcess, mkt_rf, smb, hml, rmw, cma, mom)

  # For 7 factors: intercept, mkt_rf, smb, hml, rmw, cma, mom
  coef_names <- c("(Intercept)", "mkt_rf", "smb", "hml", "rmw", "cma", "mom")
  coef_cols <- as.vector(rbind(paste0(coef_names, "_est"),
                               paste0(coef_names, "_se")))
  coefs <- data.frame(matrix(ncol = length(coef_cols) + 1, nrow = 0))
  colnames(coefs) <- c("date", coef_cols)

  stats <- data.frame(date = as.Date(character()),
                      r.squared = numeric(),
                      adj.r.squared = numeric())

  roll_zoo <- zoo::rollapplyr(
    data      = df,
    width     = window,
    by.column = FALSE,
    align     = "right",
    FUN = function(sl) {

      # Convert columns to appropriate type- for some reason,
      # does not inheret the typecasting earlier done
      # Removing this causes the regression to fail
      sl <- as.data.frame(sl)
      sl$date <- as.Date(sl$date)
      sl[, -1] <- lapply(sl[, -1], as.numeric)
      if (any(is.na(sl))) return(NULL)

      # Safety filters- throw out null
      if (nrow(sl) < 10 ||
            sd(sl[["rtexcess"]]) == 0 ||
            any(vapply(sl[, -1],
                       sd, numeric(1)) == 0)) # Any constant predictor
        return(NULL)

      # Run the linear regression
      mod <- lm(rtexcess ~ mkt_rf + smb + hml + rmw + cma + mom, data = sl)

      coef_tbl <- broom::tidy(mod)[, c("term", "estimate", "std.error")]

      # Ensure all terms are present, fill with NA if missing
      coef_tbl <- coef_tbl[match(coef_names, coef_tbl$term), ]
      # If any terms are missing, fill in with NA
      coef_tbl$estimate[is.na(coef_tbl$estimate)] <- NA
      coef_tbl$std.error[is.na(coef_tbl$std.error)] <- NA

      # Build the coefficient row
      coef_row <- c(
        max(sl$date),
        setNames(as.numeric(coef_tbl$estimate), paste0(coef_names, "_est")),
        setNames(as.numeric(coef_tbl$std.error), paste0(coef_names, "_se"))
      )

      coefs[nrow(coefs) + 1, ] <<- coef_row

      # Build the stats row
      stats_row <- data.frame(
        date = max(sl$date),
        r.squared = broom::glance(mod)$r.squared,
        adj.r.squared = broom::glance(mod)$adj.r.squared
      )

      stats <<- rbind(stats, stats_row)

    }
  )
  return(list(coefs = coefs, stats = stats ))
}

# For a given ticker:
# will run the regression and output to the appropriate directory
get_model_data <- function(ticker) {

  # Get the correct input path and throw an error if it cannot be found
  input_path <- here("output", ticker, paste0(ticker, "_merged.rds"))
  if (!file.exists(input_path)) {
    stop(glue("Cannot find {input_path}. Run data_access.R first."))
  }

  # Read the input
  merged_df <- readRDS(input_path)
  merged_df <- as.data.frame(merged_df)

  # Run the rolling regression
  res <- run_rolling_ff6(merged_df)

  # Convert this to be a date type
  res$coefs <- res$coefs %>% mutate(date = as.Date(date))

  # Save the outputs to the appropriate files
  saveRDS(res$coefs, here("output", ticker, glue("{ticker}_beta.rds")))
  saveRDS(res$stats, here("output", ticker,
                          glue("{ticker}_regression_stats.rds")))
}

#get_model_data("MSFT")