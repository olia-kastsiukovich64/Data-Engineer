"""Задача 1. Экспорт расписания рейсов по конкретному маршруту.
Нужно создать функцию на Python, которая выгружает в CSV-файл расписание рейсов между двумя городами (например, Москва и Санкт-Петербург). Функция должна включать:
- Номер рейса
- Время вылета и прилета
- Тип самолета
- Среднюю цену билета
SELECT сделать без использования pandas! """

# Самостоятельно без pandas выгрузить данные fetchall, fetchone

import psycopg2
import csv 

def get_connection():
    return psycopg2.connect(
        host="localhost",
        port="5432",
        database="demo",
        password="postgres",
        user="postgres"
    )

def export_flight_schedule(departure_city, arrival_city, filename):
    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            query = """select 
        f.flight_no,
        f.scheduled_departure,
        f.scheduled_arrival,
        ac.model,
        round(avg(tf.amount), 2) as avg_ticket_price
   	from bookings.flights f
    join bookings.airports dep on f.departure_airport = dep.airport_code
    join bookings.airports arr on f.arrival_airport = arr.airport_code
    join bookings.aircrafts ac on f.aircraft_code = ac.aircraft_code
    left join bookings.ticket_flights tf on f.flight_id = tf.flight_id
    where dep.city = %s and arr.city = %s
    group by 
        f.flight_no, 
        f.scheduled_departure, 
        f.scheduled_arrival, 
        ac.model
    order by f.scheduled_departure"""
            cursor.execute(query, (departure_city, arrival_city))
            records = cursor.fetchall()
            column_names = [desc[0] for desc in cursor.description] #извлекаем названия колонок 
            with open(filename, mode='w', encoding='utf-8', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(column_names)
                writer.writerows(records)
            print(f"Успех! Выгружено {len(records)} рейсов в файл {filename}")
    except Exception as e:
        print("Произошла ошибка", e)
    finally:
        if conn:
            conn.close()

export_flight_schedule('Москва', 'Санкт-Петербург', 'flights.csv')


""" Задача 2. Массовое обновление статусов рейсов
Создать функцию для пакетного обновления статусов рейсов (например, "Задержан" или "Отменен"). Функция должна:
- Принимать список рейсов и их новых статусов
- Подтверждать количество обновленных записей
- Обрабатывать ошибки (например, несуществующие рейсы)"""

def update_flight_statuses(flight_id, new_status):
    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            query = """
                update bookings.flights
                set status = %s
                where flight_id = %s"""
            cursor.execute(query, (new_status, flight_id))
            conn.commit()
            print(f"Cтатус для рейса {flight_id} обновлен")
    except Exception as e:
        print("Ошибка ", e)
    finally:
        if conn:
            conn.close()       

update_flight_statuses(30, 'Delayed')