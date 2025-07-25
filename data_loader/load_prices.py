'''
load_prices.py
Downloads data for the relevant tickers from yfinance and inserts
into two SQL tables.
    - securities: stores ticker name and associated long name
    - prices_daily: ticker name and associated timestamp, closing price, volume, etc.

Why we have "ON CONFLICT DO NOTHING"
https://www.dbvis.com/thetable/postgresql-upsert-insert-on-conflict-guide/#:~:text=Specifically%2C%20ON%20CONFLICT%20is%20an,the%20PostgreSQL%20upsert%20operation%20works.
- This is a tool used to perform upserts (combination of update and insert)
- A record is inserted if it does not exist and updated if it already does
- ON CONFLICT triggers a particular action when INSERT raises a UNIQUE constraint violation
- DO NOTHING will skip the insert operation

To run: docker compose run loader python load_prices.py MSFT
'''

import yfinance as yf # for Yahoo! Finance Data
import psycopg2 # for PostgreSQL
from datetime import datetime
import pandas as pd
import argparse # to allow for command-line arguments

def parse_args():
    p = argparse.ArgumentParser(description="Load daily prices into Postgres")
    p.add_argument("tickers", nargs="+", help="List of tickers, e.g. APPL, MSFT")
    p.add_argument("--start", default="2020-01-01")
    return p.parse_args()

def load_prices(TICKERS, start):
    '''
    Uses the yfinance library to insert relevant ticker data into the
    two SQL tables that store ticker name information and daily prices.
    '''
    # Establish a connection using parameters defined in .yml file
    conn = psycopg2.connect(database='factor_data',
                            user='postgres',
                            password='postgres',
                            host='db', # the name of the container that will be running database
                            port='5432')

    # Establish a cursor that will allow PostgreSQL commands to be executed
    cur = conn.cursor()

    for ticker in TICKERS:
        data = yf.download(ticker, start=start, end=datetime.today().strftime('%Y-%m-%d'))
        ticker_obj = yf.Ticker(ticker) # In order to access long name, need a ticker object
        
        long_name = ticker
        if 'longName' in ticker_obj.info.keys(): # Not all stocks have a long name associated
            long_name = ticker_obj.info['longName']

        # Sometimes yf.download will put the indices as nested if it thinks multiple tickers are being downloaded
        if isinstance(data.columns, pd.MultiIndex):
            data.columns = data.columns.get_level_values(0) # Flatten the indices

        cur.execute('INSERT INTO securities (ticker, name) VALUES (%s, %s) ON CONFLICT DO NOTHING', (ticker, long_name))

        # index is the row label, which for this dataset is the timestamp DateTimeIndex
        # row is a Series object containing the data for that row
        for index, row in data.iterrows():
            date = index.date()
            close = float(row['Close'])
            volume = int(row['Volume'])

            # Note that psycopg2 uses special postional argument formatting
            cur.execute(
                "INSERT INTO prices_daily (ticker, date, close, volume) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
                (ticker, date, close, volume)
            )
            
    conn.commit()
    cur.close()
    conn.close()

'''
Next, to ensure this is functioning correctly. Run:
docker exec -it factor_db psql -U postgres -d factor_data
SELECT * FROM prices_daily LIMIT 5;
SELECT * FROM securities LIMIT 5;
'''

if __name__ == "__main__":
    args = parse_args()
    load_prices(args.tickers, args.start)