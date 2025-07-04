# util_paths.R
# Helper function to help create directories
library(fs)
library(glue)

make_path <- function(ticker, stage, ext) {
    # ticker: MSFT, APPL, etc.
    # stage: "merged", "beta", etc.
    # ext: .rds, etc
    dir_create(path("output", ticker))
    path("output", ticker, glue("{ticker}_{stage}.{ext}"))
}