from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from datetime import datetime
import logging

# Настройка логгера
logger = logging.getLogger(__name__)


def calculate_and_log_stats(**kwargs):
    
    run_id = kwargs['run_id']
    hook = PostgresHook(postgres_conn_id="my_postgres_conn")
    
    # 3. Считаем статистику по текущему run_id
    query = f"""
        SELECT 
            count(*) as rows_count,
            sum(amount) as total_amount,
            min(amount) as min_amount,
            max(amount) as max_amount,
            avg(amount) as avg_amount
        FROM raw.lesson37_source_sales
        WHERE run_id = '{run_id}';
    """
    
    # Выполнение запроса
    result = hook.get_first(query)
    
    # Формируем словарь со статистикой
    stats = {
        "run_id": run_id,
        "rows_count": result[0],
        "total_amount": float(result[1]),
        "min_amount": float(result[2]),
        "max_amount": float(result[3]),
        "avg_amount": float(result[4])
    }
    
    # 6. Вывод в логи
    logger.info(f"--- Statistics for run: {stats['run_id']} ---")
    logger.info(f"Rows: {stats['rows_count']}, Total: {stats['total_amount']}, Avg: {stats['avg_amount']}")
    
    # 4. Передаем через XCom (в PythonOperator результат return автоматически попадает в XCom)
    return stats

with DAG(
    dag_id="HW_lesson37",
    start_date=datetime(2026,5,3),
    schedule_interval="*/5 * * * *",
    catchup=False,
    tags=["HWlesson37"]
) as dag:

    # 1. Создание таблицы-источника
    create_source_table = PostgresOperator(
        task_id="create_source_table",
        postgres_conn_id="my_postgres_conn",
        sql="""
        CREATE SCHEMA IF NOT EXISTS raw;
        CREATE TABLE IF NOT EXISTS raw.lesson37_source_sales (
            run_id TEXT NOT NULL,
            order_id TEXT NOT NULL,
            amount NUMERIC(10,2) NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            PRIMARY KEY (run_id, order_id)
        );
        """
    )

    # 2. Генерация и вставка данных
   
    generate_data = PostgresOperator(
        task_id="generate_data",
        postgres_conn_id="my_postgres_conn",
        sql="""
        INSERT INTO raw.lesson37_source_sales (run_id, order_id, amount)
        SELECT
            '{{ run_id }}',
            'ord_' || gs::text,
            round((random() * 90 + 10)::numeric, 2)
        FROM generate_series(1, 20) gs
        ON CONFLICT (run_id, order_id) DO NOTHING;
        """,
        parameters={"run_id": "{{ run_id }}"}
    )

    # 3 и 4.  Расчет cтатистики и отправка в XCom
    calculate_stats = PythonOperator(
        task_id="calculate_stats",
        python_callable=calculate_and_log_stats
    )

    # 5. Создание витрины и вставка данных
    # Данные берем из XCom предыдущего шага через Jinja template
    upsert_mart = PostgresOperator(
        task_id="upsert_mart",
        postgres_conn_id="my_postgres_conn",
        sql="""
        CREATE SCHEMA IF NOT EXISTS mart;
        CREATE TABLE IF NOT EXISTS mart.lesson37_sales_stats (
            run_id TEXT PRIMARY KEY,
            rows_count INTEGER NOT NULL,
            total_amount NUMERIC(12,2) NOT NULL,
            min_amount NUMERIC(10,2) NOT NULL,
            max_amount NUMERIC(10,2) NOT NULL,
            avg_amount NUMERIC(10,2) NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        INSERT INTO mart.lesson37_sales_stats (run_id, rows_count, total_amount, min_amount, max_amount, avg_amount)
        VALUES (
            '{{ ti.xcom_pull(task_ids="calculate_stats")["run_id"] }}',
            {{ ti.xcom_pull(task_ids="calculate_stats")["rows_count"] }},
            {{ ti.xcom_pull(task_ids="calculate_stats")["total_amount"] }},
            {{ ti.xcom_pull(task_ids="calculate_stats")["min_amount"] }},
            {{ ti.xcom_pull(task_ids="calculate_stats")["max_amount"] }},
            {{ ti.xcom_pull(task_ids="calculate_stats")["avg_amount"] }}
        )
        ON CONFLICT (run_id) DO UPDATE SET
            created_at = NOW()
        """
    )


    create_source_table >> generate_data >> calculate_stats >> upsert_mart