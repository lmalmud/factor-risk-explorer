'''
load_weights.py
Loads the information in the specified .csv file into the
portfolio_weights table.
'''

import sys
import psycopg2 # for PostgreSQL

def load_weights():
    if len(sys.argv) < 2:
        pass
        # make an error here

    # connect to the SQL server
    conn = psycopg2.connect(database='factor_data',
                            user='postgres',
                            password='postgres',
                            host='db', # the name of the container that will be running database
                            port='5432')
    
    cur = conn.cursor()

    df = pd.read_csv("path") #FIX
    for row in df:
        cur.execute()

    conn.commit()
    cur.close()
    conn.close()

'''
Next, to ensure this is functioning correctly. Run:
docker exec -it factor_db psql -U postgres -d portfolio_weights
SELECT * FROM portfolio_weights LIMIT 5;
'''