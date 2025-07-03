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

    ff5 = _get_csv_from_zip(FF_BASE + FILES["ff5"], skip=3) # There are 3 header lines
    mom = _get_csv_from_zip(FF_BASE + FILES["mom"], skip=12) # There are 12 header lines

    # The first unnamed column is labeled 'Unnamed: 0 - we know this is the date column
    ff5.rename(columns={"Unnamed: 0": "date"}, inplace=True)
    mom.rename(columns={"Unnamed: 0": "date"}, inplace=True)

    # keep only rows that look like YYYYMMDD
    ff5 = ff5[ff5["date"].str.len() == 8]
    mom = mom[mom["date"].str.len() == 8]

    # for each of the dataframes, convert the date column to datetime object
    for df in (ff5, mom):
        df["date"] = pd.to_datetime(df["date"], format="%Y%m%d")

    # convert % → decimals
    pct_cols = [c for c in ff5.columns if c != "date"]
    ff5[pct_cols] = ff5[pct_cols] / 100.0
    mom["Mom"] = mom["Mom"] / 100.0

    # left join into one dataframe
    factors = ff5.merge(mom[["date", "Mom"]], on="date", how="left")
    
    # Connection is exactly the same as in load_prices.py
    conn = psycopg2.connect(database='factor_data',
                            user='postgres',
                            password='postgres',
                            host='db',
                            port='5432')
    cur = conn.cursor()

    insert = """
        INSERT INTO factors_daily
          (date, mkt_rf, smb, hml, rmw, cma, mom, rf)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (date) DO UPDATE SET
          mkt_rf = EXCLUDED.mkt_rf,
          smb    = EXCLUDED.smb,
          hml    = EXCLUDED.hml,
          rmw    = EXCLUDED.rmw,
          cma    = EXCLUDED.cma,
          mom    = COALESCE(EXCLUDED.mom, factors_daily.mom),
          rf     = EXCLUDED.rf;
        """
    # ON CONFLICT (date) handles the case where a row with the same date
    # already exists in the table
    # Instead, it updates the row with the new values
    # EXCLUDED refers to the new data
    # COALESCE: if the new value for mom is not NULL, it replaces the old value
    # otherwise, the existing value is kept
    
    # Add relevanmt data for each row
    for _, r in factors.iterrows():
        cur.execute(insert, (
            r["date"], r["Mkt-RF"], r["SMB"], r["HML"],
            r["RMW"], r["CMA"], r["Mom"], r["RF"]
        ))

    conn.commit()
    cur.close()
    conn.close()

'''
Run:
docker exec -it factor_db psql -U postgres -d factor_data
SELECT * FROM factors_daily LIMIT 5;
'''