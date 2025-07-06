# pipeline.R
# To run: docker compose run r-model Rscript R/pipeline.R AMZN
# End-to-end driver for a single run

suppressPackageStartupMessages({
  library(here)
  library(glue)
  library(fs)
})

cat("Starting pipeline.R\n")

#1 Get command-line arguments
# Will be a list of stocks we would like to extract data from
args <- commandArgs(trailingOnly = TRUE)
tickers <- if (length(args) == 0) {
  c("AAPL", "MSFT", "AMZN", "GOOG", "META")
} else {
  toupper(args)
}

#2 Source the modular scripts
# local = TRUE refers to the environment from where source is called
source(here("R", "data_access.R"), local = TRUE) # all data and SQL commands
source(here("R", "modeling.R"), local = TRUE) # get_model_data, run_rolling_ff6
source(here("R", "plotting.R"), local = TRUE) # plot_factor_betas
source(here("R", "attribution.R"), local = TRUE) # performance_attribution
source(here("R", "weights.R"), local = TRUE) # load_weights
source(here("R", "exposures.R"), local = TRUE)

#3 Helper: safe wrapper that logs errors but continues loop
safe_run <- function(tkr, expr) {
  tryCatch(expr,
           error = function(e) {
             message(glue("[{tkr}] ✖ {conditionMessage(e)}"))
           })
}


# 4 Mail loop over tickers
for (tkr in tickers) {

  message(glue("\n=== {tkr} ===================================="))

  ## 4-A  data ingest & clean -> output/<tkr>/<tkr>_merged.rds
  message(glue("\t {tkr} ACCESS"))
  safe_run(tkr, {
    get_merged_data(tkr) # from data_access.R
  })

  ## 4-B  rolling regression
  # -> output/<tkr>/<tkr>_beta.rds, output/<tkr>/<tkr>_regression_stats.rds
  message(glue("\t {tkr} ROLLING REGRESSION"))
  safe_run(tkr, {
    merged <- readRDS(here("output", tkr, glue("{tkr}_merged.rds")))
    res <- run_rolling_ff6(merged, window = 252) # modeling.R
    dir_create(here("output", tkr))
    saveRDS(res$coefs, here("output", tkr, glue("{tkr}_beta.rds")))
    saveRDS(res$stats,  here("output", tkr, glue("{tkr}_regression_stats.rds")))
  })

  ## 4-C  beta-lines plot -> output/<tkr>/<tkr>_beta.png
  message(glue("\t {tkr} BETA PLOT"))
  safe_run(tkr, {
    plot_factor_betas( # plotting.R
      readRDS(here("output", tkr, glue("{tkr}_beta.rds"))),
      ticker   = tkr
    )
  })

  ## 4-D  factor attribution -> output/<tkr>/<tkr>_attribution.png
  message(glue("\t {tkr} FACTOR ATTRIBUTION"))
  safe_run(tkr, {
    merged   <- readRDS(here("output", tkr, glue("{tkr}_merged.rds")))
    betas_df <- readRDS(here("output", tkr, glue("{tkr}_beta.rds")))
    performance_attribution( # attribution.R
      merged_df = merged,
      betas_df  = betas_df,
      ticker    = tkr,
      save_png  = TRUE
    )
  })

  ## 4-E portfolio weights
  message(glue("\t {tkr} PORTFOLIO WEIGHTS"))
  safe_run(tkr, {
    weights_df <- load_weights()
    expos <- portfolio_exposures(weights_df)
    saveRDS(expos, here("output", "portfolio_exposures.rds"))
  })
}

message(glue("\n{tkr} PIPELINE COMPLETE."))
