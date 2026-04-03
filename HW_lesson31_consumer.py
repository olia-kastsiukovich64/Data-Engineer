import json
import psycopg2
import os
from confluent_kafka import Consumer, KafkaError 
from dotenv import load_dotenv

# Загружаем переменные окружения
load_dotenv("file.env")

# Подключение к БД
print(f"Пытаюсь подключиться к: host={os.getenv('host')}, port={os.getenv('port')}")

conn = psycopg2.connect(host=os.getenv('host'), port=os.getenv('port'), database=os.getenv('database'), 
                        user=os.getenv('user'), password=os.getenv('password'))
cursor = conn.cursor()
topic_name = 'user_events'
group_id = 'user_events_consumer_group'

conf = {
    'bootstrap.servers': 'localhost:9094',
    'group.id': group_id,
    'auto.offset.reset': 'earliest'
}
def insert_to_db(data: dict):
    #Проверка типа события
    if data['event'] == 'login':
        current_table = 'login_events'
    else:
        current_table = 'logout_events'

    query = f"INSERT INTO {current_table} (user_id, dt) VALUES (%s, %s)"
    cursor.execute(query, (data['user_id'], data['timestamp']))
    conn.commit()
    
consumer = Consumer(conf)
consumer.subscribe([topic_name])
print("Waiting for message...")

try:
    print("Stream on")
    while True:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                print(f"End of partition {msg.partition()}")
            else:
                print(f"Error {msg.error()}")
        else:
            data = json.loads(msg.value().decode('utf-8'))
            insert_to_db(data)
            print(f"Got a message: {data}")

except KeyboardInterrupt:
    print("Stream off")
finally:
    cursor.close()
    conn.close()
    consumer.close() 