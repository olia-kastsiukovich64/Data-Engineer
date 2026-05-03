import sqlite3
import requests
from pprint import pprint 
import psycopg2 as ps
from dotenv import load_dotenv
import os

#получает данные по API и записываем в список кортежей


def get_country_data(url):
    country_list=[]
    try:
        response=requests.get(url)
        if response.status_code==200:
            countries=response.json() 
            for country in countries:
                cca2=country.get('cca2')
                name=country.get('name', {}).get('common')        
                if cca2 and name:
                    country_list.append((cca2, name))
        else:
            print(f"API вернул ошибку: {response.status_code}")
    except Exception as e:
        print(f"Ошибка при запросе к API: {e}")

    return country_list   
        

load_dotenv(".env")

#вставляем данные в табличку countries в PostgreSQL

def load_countries(country_list):
    try:
        with ps.connect(host=os.getenv('host'), port=os.getenv('port'), database=os.getenv('database'), 
                        user=os.getenv('user'), password=os.getenv('password')) as con:
            with con.cursor() as cur:
                query = '''
                    INSERT INTO dds.countries (country_code, country_name) 
                    VALUES (%s, %s) 
                    ON CONFLICT (country_code) DO NOTHING
                '''
                
                # Используем executemany для пакетной вставки
                cur.executemany(query, country_list)
                
            # con.commit() выполнится автоматически при выходе из блока 'with con'
            print(f"Успешно обработано {len(country_list)} записей.")
            
    except ps.Error as e:
        print(f"Ошибка при вставке countries в PostgreSQL: {e}")


#считываем данные из sqlite и записываем их в переменную data

conn=sqlite3.connect('source_data.db')
cursor=conn.cursor()
cursor.execute('''SELECT * FROM TRANSACTIONS ''')
data=cursor.fetchall()
conn.close()

#получаем данные для таблиц и убираем дубликаты для users и products через добавление в словарь

users = {}
products = {}
transactions = []

for row in data:
    (id_, user_name, user_email, country_code, product_name, quantity, price,
     total_amount, transaction_date, ip_address) = row   #дает каждому элементу кортежа понятное имя
    
    if user_email not in users:
        users[user_email] = (user_name, user_email, country_code)

    if product_name not in products:
        products[product_name] = (product_name, price)

    transactions.append((id_, user_email, product_name, quantity, price,
                         total_amount, transaction_date, ip_address))

#Загружаем данные в Postgres
def load_to_dds(users_dict, products_dict, transactions_rows):
    try:
        with ps.connect(host=os.getenv('host'), port=os.getenv('port'), database=os.getenv('database'), 
                        user=os.getenv('user'), password=os.getenv('password')) as con:
            with con.cursor() as cur:

                # Вставляем данные в табличку users
                for email, user_data in users_dict.items():
                    cur.execute('''INSERT INTO dds.users
                                   (user_name, user_email, country_code)
                                   VALUES (%s, %s, %s)
                                   ON CONFLICT (user_email) DO UPDATE SET loaded_at = NOW()
                                   RETURNING user_id''', user_data)
                    users_dict[email] = cur.fetchone()[0]           #заменяем в исходном словаре данные на user_id по ключу email 

                # Вставляем данные в табличку products
                for product_name, product_data in products_dict.items():
                    cur.execute('''INSERT INTO dds.products
                                   (product_name, current_price)
                                   VALUES (%s, %s)
                                   ON CONFLICT (product_name) DO UPDATE SET loaded_at = NOW()
                                   RETURNING product_id''', product_data)
                    products_dict[product_name] = cur.fetchone()[0]         #заменяем в исходном словаре данные на product_id по ключу product_name 

                # Вставляем данные в табличку transactions
                for row in transactions_rows:
                    # Находим id в наших словарях по ключам user_email (row[1]) и product_name (row[2])
                    user_id = users_dict[row[1]]
                    product_id = products_dict[row[2]]

                    cur.execute('''INSERT INTO dds.transactions
                                   (id, user_id, product_id, quantity, price,
                                    total_amount, transaction_date, ip_address)
                                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                                   ON CONFLICT (id) DO UPDATE SET loaded_at = NOW()''',
                                   (row[0], user_id, product_id, row[3], row[4], row[5], row[6], row[7]))

        print(f"Загружено: users={len(users_dict)}, "
              f"products={len(products_dict)}, "
              f"transactions={len(transactions_rows)}")

    except (Exception, ps.DatabaseError) as error:
        print(f"Ошибка при загрузке в Postgres: {error}")


if __name__ == "__main__":
    countries = get_country_data('https://restcountries.com/v3.1/all?fields=name,cca2')
    load_countries(countries)
    load_to_dds(users, products, transactions)
