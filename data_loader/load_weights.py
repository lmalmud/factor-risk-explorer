'''
load_weights.py
Loads the information in the specified .csv file into the
portfolio_weights table.
'''

import sys
import psycopg2 # for PostgreSQL
import pandas as pd # to read dataframe

def load_weights():

    # Ensure that a source file was provided
    if len(sys.argv) < 2:
        raise ValueError("Must pass argument for .csv file with weight informtion.")
    path = sys.argv[1]

    # Read the weights value
    df = pd.read_csv(path, index_col = 'date')

    # connect to the SQL server
    conn = psycopg2.connect(database='factor_data',
                            user='postgres',
                            password='postgres',
                            host='db', # the name of the container that will be running database
                            port='5432')
    
    cur = conn.cursor()
    
    for index, row in df.iterrows():
        
        # Extract column information and enforce schema
        date = pd.to_datetime(index)
        ticker = row['ticker']
        weight = float(row['weight'])

        # Insert into table if not already there
        cur.execute("INSERT INTO portfolio_weights (date, ticker, weight) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                    (date, ticker, weight))

    conn.commit()
    cur.close()
    conn.close()

if __name__ == "__main__":
    load_weights()

'''
Next, to ensure this is functioning correctly. Run:
docker exec -it factor_db psql -U postgres -d factor_data
SELECT * FROM portfolio_weights LIMIT 5;
'''