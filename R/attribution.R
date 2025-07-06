# attribution.R
# Reads in the beta and merged tables and generates plots to try
# and explain the returns of the stocks
# Run: docker compose run r-model Rscript R/attribution.R

suppressPackageStartupMessages({
  library(glue) # for string concatenation
  library(dplyr) # for database modification
  library(ggplot2) # for plotting
  library(tidyr) # for pivot longer
})

performance_attribution <- function(merged_df,
                                    betas_df,
                                    ticker,
                                    save_png = TRUE) {

  # Ensure both date columns are Date type
  merged_df$date <- as.Date(merged_df$date)
  betas_df$date  <- as.Date(betas_df$date)

  factor_names <- c("mkt_rf", "smb", "hml", "rmw", "cma", "mom")

  contr <- merged_df %>%
    select(date, rtexcess, all_of(factor_names)) %>%

    # Combine with the estimates dataframe
    inner_join(betas_df, by = "date") %>%

    # Don't want the intercept data
    select(-c("(Intercept)_se", "(Intercept)_est")) %>%

    mutate(across(.cols = all_of(factor_names),
                  .fns  = function(f_ret) {
                    nm <- cur_column() # Get the current column
                    beta_col <- paste0(nm, "_est")
                    f_ret * betas_df[[beta_col]] # Multiply from row in beta_df
                  },
                  .names = "ctr_{.col}")) %>%  # keep original factor names
    select(date, rtexcess, starts_with("ctr_"))

  cuml <- contr %>%
    # replace all columns whose names begin with ctr_ with their cumulative sums
    mutate(across(starts_with("ctr_"), cumsum)) %>%

    # computes daily residual return:
    # subtract all parts explained by the factors
    # alpha: daily idisynchratic component
    # positive: stock out-performed what exposure would predict
    # negative: stock under-performed
    mutate(alpha = rtexcess - rowSums(across(starts_with("ctr_"))),

           # whether stock has persistent outperformance
           cum_alpha = cumsum(alpha), # running total daily alpha

           # total benchmark return you are trying to explain
           cum_excess = cumsum(rtexcess)) # running total of excess returns

  g <- cuml %>%
    select(date, cum_excess, cum_alpha, starts_with("ctr_")) %>%
    pivot_longer(-date, names_to = "series", values_to = "cum_return") %>%
    ggplot(aes(date, cum_return, colour = series)) +
    geom_line() +
    guides(colour = guide_legend(ncol = 2)) +
    labs(title = glue("Cumulative Factor Attribution — {ticker}"))

  if (save_png) {
    ggsave(glue("output/{ticker}/{ticker}_attribution.png"), g,
           width = 8, height = 4, dpi = 300)
  }

}

#ticker <- "MSFT"
#merged_path <- glue("output/{ticker}/{ticker}_merged.rds")
#merged_df <- readr::read_rds(merged_path)
#betas_path <- glue("output/{ticker}/{ticker}_beta.rds")
#betas_df <- readr::read_rds(betas_path)

#performance_attribution(merged_df, betas_df, ticker)