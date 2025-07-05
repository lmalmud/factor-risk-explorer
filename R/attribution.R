# attribution.R
# Run: docker compose run r-model Rscript R/attribution.R

library(glue)
library(dplyr)

performance_attribution <- function(merged_df,
                                    betas_df,
                                    ticker,
                                    save_png = TRUE) {

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
    mutate(across(starts_with("ctr_"), cumsum)) %>%      # cumulate factors
    mutate(alpha = rtexcess - rowSums(across(starts_with("ctr_"))),
           cum_alpha = cumsum(alpha),
           cum_excess = cumsum(rtexcess))

    print(colnames(cuml))
    print(head(cuml))

}

ticker <- "MSFT"
merged_path <- glue("output/{ticker}/{ticker}_merged.rds")
merged_df <- readr::read_rds(merged_path)
betas_path <- glue("output/{ticker}/{ticker}_beta.rds")
betas_df <- readr::read_rds(betas_path)

performance_attribution(merged_df, betas_df, ticker)