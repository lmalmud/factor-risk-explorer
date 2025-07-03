'''
load_factors.py
Loads Fama-French daily factors into factors_daily table.
'''

import psycopg2
import pandas as pd
import io, zipfile, requests # for downloading the zip files

FF_BASE = "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/"

FILES = {
    "ff5": "F-F_Research_Data_5_Factors_2x3_daily_CSV.zip",
    "mom": "F-F_Momentum_Factor_daily_CSV.zip",
}

def _get_csv_from_zip(zip_url: str, skip: int) -> pd.DataFrame:
    r = requests.get(zip_url, timeout=30)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    
    # the first file in the zip is always the CSV
    csv_name = z.namelist()[0]
    return pd.read_csv(z.open(csv_name), skiprows=skip)

def load_factors():
    '''
    Reads in the .csv file stored in the /data subdirectory
    into the relevant SQL table.
    '''
    # FIXME: In the future, figure out how to automatically update this file, since
    # some data will be missing
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
        print(row)
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