CREATE TABLE securities ( -- new table called securities
    -- PRIMARY KEY = no two rows can have the same value
    ticker TEXT PRIMARY KEY, -- column called "ticker" that is of type text
    name TEXT -- column called name that is of type text
);

CREATE TABLE prices_daily ( -- new table called prices_daily
    -- REFERENCES securites(ticker) creates a relationship between the two tables
    ticker TEXT REFERENCES securities(ticker), -- column called "ticker" that is duplicate from securities
    date DATE, -- column called "date" that is of type date
    close NUMERIC, -- coulmn called "close" that is of numeric type
    volume BIGINT, -- column called "volume" that is of type bigint
    PRIMARY KEY (ticker, date) -- ensure that ticker and date must be unique
);

CREATE TABLE factors_daily ( -- will store data from Fama-French library
    date DATE PRIMARY KEY,
    mkt_rf NUMERIC,
    smb NUMERIC,
    hml NUMERIC,
    rmw NUMERIC,
    cma NUMERIC,
    mom NUMERIC,
    rf NUMERIC
);

CREATE TABLE macro_daily ( -- will store data from FRED
    date DATE PRIMARY KEY,
    treasury_10y NUMERIC,
    inflation_expectation NUMERIC,
    unemployment_rate NUMERIC
);
