# Makefile

# Start up
up:
	docker compose down -v
	docker compose up -d --build
	docker compose run loader
	docker exec -i factor_db psql -U postgres -d factor_data < db/views/vw_returns.sql

# Run the R model
run-model:
	docker compose run r-model

# Clean up
down:
	docker compose down -v

# To run the interactive terminal with psql
psql:
	docker exec -it factor_db psql -U postgres -d factor_data