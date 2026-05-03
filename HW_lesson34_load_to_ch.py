import clickhouse_connect
import psycopg2 as ps
from dotenv import load_dotenv
import os

load_dotenv(".env")

def get_data():
    with ps.connect(host=os.getenv('host'), port=os.getenv('port'), database=os.getenv('database'), 
                        user=os.getenv('user'), password=os.getenv('password')) as con:
        with con.cursor() as cur:
            cur.execute('''select 
                                c.country_code, 
                                c.country_name,
                                sum(t.total_amount) as total_sales,
                                avg(t.total_amount) as avg_transactions_value,
                                count(*) as transactions_count
                            from dds.transactions t
                            join dds.users u on u.user_id = t.user_id 
                            join dds.countries c on c.country_code = u.country_code 
                            group by c.country_code;''')
            return cur.fetchall()


try:
    data = get_data()

    if not data:
        print("Нет данных для загрузки.")
    else:
        client = clickhouse_connect.get_client(host=os.getenv('CH_HOST'), port=os.getenv('CH_PORT'), username=os.getenv('CH_USER'), password=os.getenv('CH_PASSWORD'))
    
    client.insert('analytics.transaction_stats_by_country', data, column_names=['country_code', 'country_name', 'total_sales', 'avg_transactions_value', 'transactions_count'])
    print(f"Успешно загружено строк: {len(data)}")
    client.close()
except Exception as e:
    print(f"Oum6ka: {e}")   
