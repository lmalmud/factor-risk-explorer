'''
load_prices.py
'''

import yfinance as yf # for Yahoo! Finance Data
import psycopg2 # for PostgreSQL
from datetime import datetime

# Ticker is the unique shorthange for a publically traded stock or security
# These are the tickers we would like to use for this dataset
TICKERS = ['APPL', 'MSFT', 'GOOGL', 'AMZN']

# Establish a connection using parameters defined in .yml file
conn = psycopg2.connect(database='factor_data',
                        user='postgres',
                        password='postgres',
                        host='localhost',
                        port='5432')

# Establish a cursor that will allow PostgreSQL commands to be executed
cur = conn.cursor()

for ticker in TICKERS:
    data = yf.download(ticker, start='2022-01-01', end=datetime.today().strftime('%Y-%m-%d'))
    print(data)
    cur.execute('INSERT INTO securities (ticker, name) VALUES (%s, %s) ON CONFLICT DO NOTHING', (ticker, ticker))

conn.commit()
cur.close()
conn.close()