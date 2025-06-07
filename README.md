# factor-risk-explorer
A full-stack analytics tool that stores multi-asset price data in PostgreSQL, pulls it into R, runs factor &amp; risk models, and serves an interactive Shiny dashboard + auto-generated PDF reports.

# to run
Configure: make up \
Run model: make run-model \
Use interactive SQL terminal: make psql \
Clean: make down

# to clean up
Run docker compose down -v
