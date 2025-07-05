# plotting.R
# Plot rolling Fama-French-5 + Momentum betas
# Run: docker compose run r-model Rscript R/plotting.R MSFT

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr) # for to_pivot_longer
  library(readr)   # for read_rds()
  library(glue)
})

plot_factor_betas <- function(beta_df, ticker, save_png = TRUE) {

  to_plot <- beta_df %>%
    select("mkt_rf_est",
           "smb_est",
           "hml_est",
           "rmw_est",
           "cma_est",
           "mom_est",
           "date") %>%

    # rename columns: drop last 4 chars, uppercase
    rename_with(~ toupper(substr(., 1, nchar(.) - 4)), -date)

  # Convert to long format for easier plotting
  to_plot_long <- to_plot %>%
    pivot_longer(cols = -date, # Will pivot on all columns except date
                 names_to = "term", # new column is called term
                 values_to = "estimate") # the value goes in "estimate"

  # Plot estimates over time
  p <- to_plot_long %>% ggplot() +
    aes(x = date, y = estimate, color = term) +
    geom_line(linewidth = 0.8, na.rm = TRUE) +
    labs(title  = glue("Rolling Six-Factor Betas — {ticker}"),
         x      = "Window end date",
         y      = "β estimate",
         colour = "Factor") +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")

  # Save the result to folder with stock information
  if (save_png) {
    ggsave(glue("output/{ticker}/{ticker}_betas_plot.png"), p,
           width = 8, height = 4.5, dpi = 300)
  }
  return(p)

}

# Example run:
# Take commandline arguments
args <- commandArgs(trailingOnly = TRUE)

# The first commandline argument is the desired stock, otherwise
ticker <- if (length(args) == 0) "AMZN" else toupper(args[1])

# Ensure that the file exists
beta_path <- glue("output/{ticker}/{ticker}_beta.rds")
if (!file.exists(beta_path)) {
  stop(glue("Cannot find {beta_path}. Run modeling.R first."))
}

# Read the input produced by modeling.R
beta_df <- readr::read_rds(beta_path)
plot_factor_betas(beta_df, ticker)