from datetime import datetime, timezone
import random
import logging
from uuid import uuid4
from pymongo import MongoClient

from airflow.decorators import dag, task
from airflow.models import Variable

logger = logging.getLogger(__name__)

@dag(
    dag_id="HW_lesson38_generator",
    start_date=datetime(2026, 5, 3),
    schedule="* * * * *", # Запуск каждую минуту
    catchup=False,
    tags=["homework"]
)
def event_generator():

    @task
    def generate_and_save_events():
        # Получаем URI подключения к Mongo из Variables Airflow
        mongo_uri = Variable.get("lesson38_mongo_uri")
        
        # Настройки генерации
        event_types = ["view", "comment", "send_hw", "question"]
        weights = [0.75, 0.02, 0.07, 0.15] 

        events = []
        # Генерируем 100 событий в минуту
        for _ in range(100):
            events.append({
                "event_id": str(uuid4()),
                "event_type": random.choices(event_types, weights=weights, k=1)[0],
                "user_login": f"student_user_{random.randint(1, 100):04d}",
                "event_ts": datetime.now(timezone.utc)
            })

        # Запись в MongoDB
        with MongoClient(mongo_uri) as client:
            db = client["source_db"]
            collection = db["events_stream"]
            result = collection.insert_many(events)
            
        logger.info(f"Сгенерировано и записано {len(result.inserted_ids)} событий.")

    generate_and_save_events()

event_generator()