# factor-risk-explorer
A full-stack analytics tool that stores multi-asset price data in PostgreSQL, pulls it into R, runs factor &amp; risk models, and serves an interactive Shiny dashboard + auto-generated PDF reports.

# to run
Every time you reopen the project: docker compose up -d
- to start the database
- if needed, will start the loader \
To interact with Postgres: docker exec -it factor_db psql -U postgres -d factor_data

When you edit code (say, in load_prices.py) \ 
Run docker compose build loader / docker compose run loader. \
- since the bind mount has been added, first line no longer necessary
Run docker compose build loader / docker compose up loader if requirements.txt or Dockerfile changed

# to clean up
Run docker compose down -v
