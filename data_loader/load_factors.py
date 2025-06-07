'''
load_factors.py
Loads Fama-French daily factors into factors_daily table.
'''

import psycopg2
import pandas as pd

def load_factors():
    '''
    Reads in the .csv file stored in the /data subdirectory
    into the relevant SQL table.
    '''
    df = pd.read_csv('data/F-F_Research_Data_5_Factors_2x3_daily.csv',
                    skiprows = 3) # There are 3 header lines

    # The first unnamed column is labeled 'Unnamed: 0 - we know this is the date column
    df.rename(columns={'Unnamed: 0': 'date'}, inplace=True) # Need to set inplace to be True, otherwise new dataframe created
    df = df[df['date'].str.len() == 8] # Remove any rows that have poorly formatted date
    df['date'] = pd.to_datetime(df['date'], format='%Y%m%d') # Convert dates to be datetime objects

    # Connection is exactly the same as in load_prices.py
    conn = psycopg2.connect(database='factor_data',
                            user='postgres',
                            password='postgres',
                            host='db',
                            port='5432')
    cur = conn.cursor()

    for _, row in df.iterrows():
        # Triple quotes will allow us to make a multi line string
        cur.execute("""
                    INSERT INTO factors_daily (date, mkt_rf, smb, hml, rmw, cma, rf)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (date) DO NOTHING
                    """, 
                    (row['date'], row['Mkt-RF'], row['SMB'], row['HML'], row['RMW'], row['CMA'], row['RF']))
        # Will add mom later

    conn.commit()
    cur.close()
    conn.close()

'''
Run:
docker exec -it factor_db psql -U postgres -d factor_data
SELECT * FROM factors_daily LIMIT 5;
'''