'''
load_macro.py
Loads the daily macroeconomic factors into the relevant table.
Uses FRED API, which allows developers to access data from the
Federal Reserve.

You can search for different datasets here: https://fred.stlouisfed.org/
The unique FRED ID will be in the URL

My API key: 178c4bfff4d35bf5d591dd34d814d000
'''

from fredapi import Fred
import pandas as pd
import psycopg2

# Access to Fred data
fred = Fred(api_key='178c4bfff4d35bf5d591dd34d814d000')

def load_macro():

    # Choose dates that we would like to select data for and build a dataframe
    dates = pd.date_range(start='2010-01-01', end='2023-12-31', freq='D')
    df = pd.DataFrame(index=dates)

    # fred.get_series will return a dataframe
    # .reindex will conform Dataframe to new index
    # .fillna is used for Nan values
    # method=ffill will propagate last valid observation to the next valid if there are holes in the information
    
    df['treasury_10y'] = fred.get_series('GS10').reindex(dates).ffill()
    df['unemployment_rate'] = fred.get_series('UNRATE').reindex(dates).ffill()
    df['inflation_expectation'] = fred.get_series('T5YIFR').reindex(dates).ffill()

    # For the first few rows, there is no inflation expectation, so omit these rows.
    # Alternate option: fill from backwards
    # Alternate option: replace with None and let later calculations decide how to handle
    df.dropna(inplace=True) # Drops any row with at least one NaN value in the original DataFrame
    
    # Establish a connection using parameters defined in .yml file
    conn = psycopg2.connect(database='factor_data',
                            user='postgres',
                            password='postgres',
                            host='db',
                            port='5432')
    cur = conn.cursor()

    # Insert each row of data into the table
    for date, row in df.iterrows():
        cur.execute('''
                    INSERT INTO macro_daily (date, treasury_10y, unemployment_rate, inflation_expectation)
                    VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING''',
                    (date.date(), float(row['treasury_10y']), float(row['unemployment_rate']), float(row['inflation_expectation'])))
        
    conn.commit()
    cur.close()
    conn.close()

'''
Run:
docker exec -it factor_db psql -U postgres -d factor_data
SELECT * FROM macro_daily LIMIT 5;
'''

load_macro()