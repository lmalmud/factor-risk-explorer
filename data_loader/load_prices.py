'''
load_prices.py
'''

import yfinance as yf # for Yahoo! Finance Data
import psycopg2 # for PostgreSQL
from datetime import datetime
import pandas as pd

# Ticker is the unique shorthange for a publically traded stock or security
# These are the tickers we would like to use for this dataset
# TICKERS = ['APPL', 'MSFT', 'GOOGL', 'AMZN']
TICKERS = ['GOOGL'] # for testing purposes

# Establish a connection using parameters defined in .yml file
conn = psycopg2.connect(database='factor_data',
                        user='postgres',
                        password='postgres',
                        host='db', # the name of the container that will be running database
                        port='5432')

# Establish a cursor that will allow PostgreSQL commands to be executed
cur = conn.cursor()

for ticker in TICKERS:
    data = yf.download(ticker, start='2022-01-01', end=datetime.today().strftime('%Y-%m-%d'))
    ticker_obj = yf.Ticker(ticker) # In order to access long name, need a ticker object

    # Sometimes yf.download will put the indices as nested if it thinks multiple tickers are being downloaded
    if isinstance(data.columns, pd.MultiIndex):
        data.columns = data.columns.get_level_values(0) # Flatten the indices

    cur.execute('INSERT INTO securities (ticker, name) VALUES (%s, %s) ON CONFLICT DO NOTHING', (ticker, ticker_obj.info['longName']))

    # index is the row label, which for this dataset is the timestamp DateTimeIndex
    # row is a Series object containing the data for that row
    for index, row in data.iterrows():
        date = index.date()
        close = float(row['Close'])
        volume = int(row['Volume'])

        
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