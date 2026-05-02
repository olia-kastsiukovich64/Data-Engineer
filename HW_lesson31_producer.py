
from confluent_kafka import Producer
import random
import json
import time
from datetime import datetime
conf = {
    'bootstrap.servers': 'localhost:9094'
}
producer = Producer(conf)
TOPIC = 'user_events'

def delivery_report(err, msg):
    if err:
        print(f"Ошбика {err}")
    else:
        print(f"Сообщение отправлено: topic={msg.topic()} partition={msg.partition()} offset={msg.offset()}")

def generate_message():
    event = random.choice(['login', 'logout'])
    user_id = random.randint(100, 999)
    return {
        "user_id": user_id,
        "event": event,
        "timestamp": datetime.now().isoformat()
    }

try:
    while True:
        msg = generate_message()
        producer.produce(TOPIC, value=json.dumps(msg), callback=delivery_report)
        producer.poll(0)
        time.sleep(0.1)
except KeyboardInterrupt:
    print('Остановили генерацию сообщений')
finally:
    producer.flush()