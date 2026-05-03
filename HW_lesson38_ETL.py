from datetime import datetime
import logging
from pymongo import MongoClient

from airflow.decorators import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.models import Variable
from airflow.operators.python import get_current_context

logger = logging.getLogger(__name__)

@dag(
    dag_id="HW_lesson38_ETL",
    start_date=datetime(2026, 5, 3),
    schedule="*/10 * * * *", 
    catchup=True, #нужен чтобы обработать пропущенные интервалы
    tags=["homework"]
)
def etl_pipeline():

    @task
    def load_to_raw():
        #Экстракт из Mongo и загрузка в таблицу сырых данных raw.events
        mongo_uri = Variable.get("lesson38_mongo_uri")
        
        # Получаем временной интервал запуска DAG (ровно 10 минут)
        context = get_current_context()
        window_start = context["data_interval_start"]
        window_end = context["data_interval_end"]

        # Чтение из MongoDB за нужный период
        with MongoClient(mongo_uri) as client:
            coll = client["source_db"]["events_stream"]
            rows = list(coll.find({
                "event_ts": {"$gte": window_start, "$lt": window_end}
            }))

        if not rows:
            logger.info("Нет данных за этот период")
            return "no_data"

        # Форматируем данные для Postgres
        prepared_rows = [
            (r["event_id"], r["event_type"], r["user_login"], r["event_ts"])
            for r in rows
        ]

        #  Запись в Postgres (схема raw)
        pg_hook = PostgresHook(postgres_conn_id="warehouse_postgres_conn")
        
        # Создаем таблицу, если её нет
        pg_hook.run("""
            CREATE SCHEMA IF NOT EXISTS raw;
            CREATE TABLE IF NOT EXISTS raw.events (
                event_id UUID PRIMARY KEY,
                event_type TEXT,
                user_login TEXT,
                event_ts TIMESTAMPTZ,
                load_ts TIMESTAMPTZ DEFAULT NOW()
            );
        """)

        # Вставляем данные
        insert_sql = """
            INSERT INTO raw.events (event_id, event_type, user_login, event_ts)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (event_id) DO NOTHING;
        """
        
        conn = pg_hook.get_conn()
        with conn.cursor() as cur:
            cur.executemany(insert_sql, prepared_rows)
        conn.commit()
        
        return "success" 

    @task
    def transform_to_dds(status):
        #Переносим данные в DDS, создаем отдельные таблицы users и events в схеме dds

        if status == "no_data":
            logger.info("Новых данных нет.")
            return

        pg_hook = PostgresHook(postgres_conn_id="warehouse_postgres_conn")
        
        setup_sql = """
        CREATE SCHEMA IF NOT EXISTS dds;
        
        CREATE TABLE IF NOT EXISTS dds.users (
            user_login TEXT PRIMARY KEY,
            first_seen_ts TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS dds.events (
            event_id UUID PRIMARY KEY,
            event_type TEXT,
            user_login TEXT REFERENCES dds.users(user_login),
            event_ts TIMESTAMPTZ
        );
        """
        pg_hook.run(setup_sql)

        # UPSERT пользователей (добавляем только новых)
        upsert_users = """
        INSERT INTO dds.users (user_login, first_seen_ts)
        SELECT DISTINCT user_login, MIN(event_ts)
        FROM raw.events
        GROUP BY user_login
        ON CONFLICT (user_login) DO NOTHING;
        """
        
        # UPSERT событий
        upsert_events = """
        INSERT INTO dds.events (event_id, event_type, user_login, event_ts)
        SELECT event_id, event_type, user_login, event_ts
        FROM raw.events
        ON CONFLICT (event_id) DO NOTHING;
        """

        pg_hook.run(upsert_users)
        pg_hook.run(upsert_events)

    
    transform_to_dds(load_to_raw())

etl_pipeline()