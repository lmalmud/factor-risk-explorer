# Makefile

# clean
down:
	docker compose down -v

# psql 
psql:
	docker exec -it factor_db psql -U postgres -d factor_data

app:
	docker compose run --rm -p 3838:3838 r-model \
	Rscript -e "shiny::runApp('shiny', host='0.0.0.0', port=3838)"