# Makefile

# clean
down:
	docker compose down -v

# psql 
psql:
	docker exec -it factor_db psql -U postgres -d factor_data