-- Вывести аэропорты, из которых выполняется менее 50 рейсов
select 
	a.airport_name, 
	f.departure_airport, 
	count(*)
from airports a 
join flights f on a.airport_code = f.departure_airport
group by a.airport_name, f.departure_airport 
having count(*) < 50
order by count(*) desc 

--Вывести среднюю стоимость билетов для каждого маршрута (город вылета - город прилета)


select 
	round(avg(amount), 2) as avg_ticket_amount, 
	dep.city as city_departure, 
	arr.city as city_arrival
from ticket_flights tf 
join flights f on f.flight_id = tf.flight_id 
join airports dep on dep.airport_code = f.departure_airport  
join airports arr on arr.airport_code = f.arrival_airport 
group by dep.city, arr.city
order by avg_ticket_amount desc; 

--Вывести топ-5 самых загруженных маршрутов (по количеству проданных билетов)

select 
    dep.city as departure_city,
    arr.city as arrival_city,
    count(tf.ticket_no) as tickets_sold
from ticket_flights tf
join flights f on tf.flight_id = f.flight_id
join airports dep on f.departure_airport = dep.airport_code
join airports arr on f.arrival_airport = arr.airport_code
group by dep.city, arr.city
order by tickets_sold desc
limit 5;


--Найти пары рейсов, вылетающих из одного аэропорта в течение 1 часа
 
select distinct on (f1.flight_id, f2.flight_id)
    f1.flight_id as flight_1,
    f2.flight_id as flight_2, 
    dep.city
from flights f1
join flights f2
  on f1.departure_airport = f2.departure_airport
  and f1.flight_id <> f2.flight_id   -- исключаем дубликаты из-за self-join
join airports dep on dep.airport_code = f1.departure_airport
where abs (extract(epoch from (f1.scheduled_departure - f2.scheduled_departure ))) <= 3600
group by f1.flight_id, f2.flight_id, dep.city;


--Проанализировать данные о продажах билетов, чтобы получить статистику в следующих разрезах:
-- По классам обслуживания (fare_conditions)

select
	tf.fare_conditions,
	count(tf.fare_conditions) as count,
	round(avg(tf.amount), 2) as avg
from ticket_flights tf 
group by tf.fare_conditions 
order by 2 desc
;

-- По месяцам вылета 
select
	extract (month from f.scheduled_arrival) as month, 
	count(distinct tf.ticket_no) as tickets, 
	count(distinct tf.flight_id) as flight
from ticket_flights tf 
join flights f on tf.flight_id = f.flight_id
group by month
order by 2 desc
; 

-- По аэропортам вылета
select
	f.departure_airport, 
	count(distinct tf.ticket_no) as tickets, 
	count(distinct tf.flight_id) as flight
from ticket_flights tf 
join flights f on tf.flight_id = f.flight_id
group by f.departure_airport 
order by 2 desc
; 

-- По комбинациям: класс + месяц, класс + аэропорт, месяц + аэропорт
select
	count(distinct tf.ticket_no) as tickets, 
	extract (month from f.scheduled_arrival) as month, 
	tf.fare_conditions, 
	f.departure_airport
from ticket_flights tf 
join flights f on tf.flight_id = f.flight_id
group by grouping sets (
	(tf.fare_conditions, month),
	(tf.fare_conditions, f.departure_airport),
	(month, f.departure_airport)
);

-- Общие итоги
select
	count(distinct tf.ticket_no) as tickets, 
	extract (month from f.scheduled_arrival) as month, 
	tf.fare_conditions, 
	f.departure_airport
from ticket_flights tf 
join flights f on tf.flight_id = f.flight_id
group by 
	rollup (month, tf.fare_conditions, f.departure_airport);

--Найдите рейсы, задержка которых превышает среднюю задержку по всем рейсам. Рейсы с задержкой больше средней (через CTE).

with avg_flight_delay as (
	select round(avg(extract (epoch from (f.actual_departure - f.scheduled_departure) / 60) ), 2) as avg_delay 
	from flights f 
),
flight_delay as (
	select 
		flight_id,
		round(extract (epoch from (f.actual_departure - f.scheduled_departure) / 60), 2) as delay
	from flights f 
	where f.actual_departure is not null 
)
select 
	fd.flight_id,
	fd.delay
from flight_delay fd
cross join avg_flight_delay afd 
where 
	fd.delay > afd.avg_delay
order by 2 desc
;	


