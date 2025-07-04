# plotting.R
# Plot rolling Fama-French-5 + Momentum betas
# Run: docker compose run r-model Rscript R/plotting.R MSFT

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)   # for read_rds()
  library(glue)
})

plot_factor_betas <- function(beta_ts, ticker, save_png = TRUE) {
  print(head(beta_ts))
  print(colnames(beta_ts))
  p <- beta_ts %>%
    filter(term != "(Intercept)") %>%           # drop alpha
    mutate(term = toupper(term)) %>%            # prettier legend
    ggplot(aes(x = window_end, y = estimate, colour = term)) +
      geom_line(linewidth = 0.8, na.rm = TRUE) +
      labs(title  = glue("Rolling Six-Factor Betas — {ticker}"),
           x      = "Window end date",
           y      = "β estimate",
           colour = "Factor") +
      theme_minimal(base_size = 12) +
      theme(legend.position = "bottom")

  if (save_png) {
    ggsave(glue("output/ticker/{ticker}_betas_plot.png"), p,
           width = 8, height = 4.5, dpi = 300)
  }
  return(p)
}

# ---- script interface --------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

# the first commandline argument is the desired stock, otherwise
ticker <- if (length(args) == 0) "AMZN" else toupper(args[1])

beta_path <- glue("output/{ticker}/{ticker}_beta.rds")
if (!file.exists(beta_path)) {
  stop(glue("Cannot find {beta_path}. Run modeling.R first."))
}

# read the input produced by modeling.R
beta_ts <- readr::read_rds(beta_path)
plot_factor_betas(beta_ts, ticker)