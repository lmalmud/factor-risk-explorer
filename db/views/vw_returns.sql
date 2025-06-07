-- deltes table if it exists
DROP MATERIALIZED VIEW IF EXISTS vw_returns; 
-- DROP: deletes an existing object https://www.postgresql.org/docs/current/sql-dropmaterializedview.html

-- materialized view vs. view: https://www.geeksforgeeks.org/differences-between-views-and-materialized-views-in-sql/
-- we want to store results for faster access,
-- where a view would only store the query expression

-- AS introduces the query whose output is going to define the view
-- https://chatgpt.com/g/g-p-683dc1cc325c8191a0a9b93b98076342-factor-driven/c/683dc22a-d990-8006-8a85-bc3f988b71f4
CREATE MATERIALIZED VIEW vw_returns AS
    -- WITH creates a temporarily named result: https://www.postgresql.org/docs/current/queries-with.html
    WITH log_returns AS (
        -- SELECT get the columns (and computation) from prices_daily
        SELECT 
            ticker,
            date,
            /**
            we are creating a window function, which performs calculations over rows that are related to current query row
            https://www.postgresql.org/docs/current/functions-window.html
            PARTITION BY will restart window for each ticker
            OVER will specify how we want this window function to be applied
            **/
            LN(close / LAG(close) OVER (PARTITION BY ticker ORDER BY date)) AS log_ret
            FROM prices_daily
    ),
    /**
    We use the zero mean assumption as a good approximation for volatility.
    So, replacing the mean as zero gives the following formula for standard deviation.
    **/
    volatility AS (
        SELECT
            ticker,
            date,
            log_ret,
            -- monthly window
            AVG(log_ret * log_ret) OVER (PARTITION BY ticker ORDER BY date ROWS BETWEEN 20 PRECEDING AND CURRENT ROW)::NUMERIC ^ .5 AS vol_21d,
            -- three month window
            AVG(log_ret * log_ret) OVER (PARTITION BY ticker ORDER BY date ROWS BETWEEN 62 PRECEDING AND CURRENT ROW)::NUMERIC ^ .5 AS vol_63d,
            -- yearly window
            AVG(log_ret * log_ret) OVER (PARTITION BY ticker ORDER BY date ROWS BETWEEN 251 PRECEDING AND CURRENT ROW)::NUMERIC ^ .5 AS vol_252d
            FROM log_returns
    )

SELECT * FROM volatility
-- LAG returns NULL for the first row in every window
WHERE log_ret IS NOT NULL; 

/**
to run:
docker exec -i factor_db psql -U postgres -d factor_data < db/views/vw_returns.sql

to test:
docker exec -it factor_db psql -U postgres -d factor_data
SELECT * FROM vw_returns LIMIT 10;
SELECT * FROM vw_returns WHERE ticker = 'MSFT' LIMIT 10;

when new data comes in, since this view is materialized, we will need to refresh:
REFRESH MATERIALIZED VIEW vw_returns;

Note that this table has an index: CREATE INDEX IF NOT EXISTS idx_vw_returns_ticker_date ON vw_returns(ticker, date);
Add an index for faster queries: https://www.w3schools.com/sql/sql_create_index.asp
We make indices for both ticker and date

To test, run:
EXPLAIN ANALYZE
SELECT *
FROM vw_returns
WHERE ticker = 'AAPL'
  AND date >= '2024-01-01';

**/