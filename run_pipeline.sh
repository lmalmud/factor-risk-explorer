#!/usr/bin/env bash

# If you are getting permissions errors...
# sudo chown -R $USER:$USER output
# You can find your group by: id -gn and changing
# what is after the colon
#chmod -R 775 output

export UID=$(id -u)
export GID=$(id -g)

set -euo pipefail

TICKERS=("$@")
if [[ ${#TICKERS[@]} -eq 0 ]]; then
  TICKERS=(AAPL MSFT AMZN GOOGL META)
fi

# spin up the database (detached so scripts can attach)
docker compose up -d db

# load factors & macro (all rows; no args)
docker compose run --rm loader python load_factors.py
docker compose run --rm loader python load_macro.py

# load prices for the requested tickers
docker compose run --rm loader python load_prices.py "${TICKERS[@]}"

# load portfolio weights from the .csv
docker compose run --rm loader python load_weights.py data/weights_2025-07-08.csv

docker exec -i factor_db psql -U postgres -d factor_data < db/views/vw_returns.sql

# run the R analytics pipeline
docker compose run --rm r-model Rscript R/pipeline.R "${TICKERS[@]}"

# To run: ./run_pipeline.sh TSLA NVDA