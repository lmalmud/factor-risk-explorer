# --------------------------------------------------------------------
# Makefile – dev conveniences for Factor-Driven project
# --------------------------------------------------------------------
# Usage examples
#   make up                # start db, load all data, build views
#   make run TICKERS="TSLA NVDA"   # run full analytic pipeline
#   make down              # stop & remove everything
#   make psql              # open interactive psql shell
# --------------------------------------------------------------------

.SILENT:          # keep output clean
.PHONY: up loaders views run down psql

# -- 1. spin up the db ------------------------------------------------------
up: down
	echo "🗄️  Launching Postgres ..."
	docker compose up -d db

# -- 2. load factors, macro, prices ----------------------------------------
loaders:
	echo "📥 Loading factors & macro ..."
	docker compose run --rm loader load_factors.py
	docker compose run --rm loader load_macro.py
	echo "📥 Loading prices (default tickers) ..."
	docker compose run --rm loader load_prices.py AAPL MSFT AMZN GOOGL META

# -- 3. create / refresh SQL views -----------------------------------------
views:
	echo "🛠️  (Re)building vw_returns view ..."
	docker exec -i factor_db psql -U postgres -d factor_data \
	  -f /docker-entrypoint-initdb.d/init.sql
	docker exec -i factor_db psql -U postgres -d factor_data \
	  -f db/views/vw_returns.sql

# -- aggregate target -------------------------------------------------------
up: loaders views
	echo "✅  Database ready"

# -- 4. run the full R analytics pipeline ----------------------------------
# override tickers: make run TICKERS="TSLA NVDA"
TICKERS ?= AAPL MSFT AMZN GOOGL META

run:
	echo "📊 Running R pipeline for: $(TICKERS)"
	docker compose run --rm r-model Rscript R/pipeline.R $(TICKERS)
	echo "✅  Artefacts written to ./output/"

# -- 5. tear everything down ------------------------------------------------
down:
	docker compose down -v

# -- 6. quick psql shell ----------------------------------------------------
psql:
	docker exec -it factor_db psql -U postgres -d factor_data
