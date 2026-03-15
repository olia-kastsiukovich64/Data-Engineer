/*
1. Определить среднюю загрузку самолетов (процент занятых мест) для каждого рейса -
 только успешно совершившего перелет (status = 'Arrived') и вылетевших в сентябре 2016 года.

Используем таблицы:
flights для получения информации о рейсах.
aircrafts для получения общей вместимости самолета.
seats для подсчета общего числа мест.
boarding_passes для подсчета фактически занятых мест.

2. Провести оптимизацию скрипта по необходимости и показать разницу в затраченных ресурсов и преимуществе.
 
*/
explain analyze
with total_seats_per_aircraft as (
	select aircraft_code, 
	count(seat_no) as total_seats
	from bookings.seats
	group by aircraft_code
),
booked_seats_per_flights as (
	select flight_id,
	count(seat_no) as booked_seats
	from bookings.boarding_passes
	where seat_no is not null
	group by flight_id
)
select 
	f.flight_id, 
	f.flight_no, 
	ts.total_seats,
	bs.booked_seats,
	round((bs.booked_seats * 100.0)/ts.total_seats, 2) as loaded_percent,  --умножаем на 100.0 чтобы привести к типу numeric и исключить 0 
	extract (month from f.scheduled_departure) as month, 
	extract (year from f.scheduled_departure) as year 
from bookings.flights f 
join total_seats_per_aircraft ts on ts.aircraft_code = f.aircraft_code 
join booked_seats_per_flights bs on bs.flight_id = f.flight_id   
where f.status = 'Arrived' and extract (month from f.scheduled_departure) = '9' 
and extract (year from f.scheduled_departure) = '2016'
order by loaded_percent asc;

--Execution Time: 631.304 ms 

-- создаем индекс на scheduled_departure для оптимизации
create index idx_flights_scheduled_departure
on bookings.flights (scheduled_departure);

drop index idx_flights_scheduled_departure

--изменяем условие where в исходном запросе для использования индекса
explain analyze
with total_seats_per_aircraft as (
	select aircraft_code, 
	count(seat_no) as total_seats
	from bookings.seats
	group by aircraft_code
),
booked_seats_per_flights as (
	select flight_id,
	count(seat_no) as booked_seats
	from bookings.boarding_passes
	where seat_no is not null
	group by flight_id
)
select 
	f.flight_id, 
	f.flight_no, 
	ts.total_seats,
	bs.booked_seats,
	round((bs.booked_seats * 100.0)/ts.total_seats, 2) as loaded_percent,  --умножаем на 100.0 чтобы привести к типу numeric и исключить 0 
	extract (month from f.scheduled_departure) as month, 
	extract (year from f.scheduled_departure) as year 
from bookings.flights f 
join total_seats_per_aircraft ts on ts.aircraft_code = f.aircraft_code 
join booked_seats_per_flights bs on bs.flight_id = f.flight_id   
where f.status = 'Arrived' and f.scheduled_departure >= '2016-09-01 00:00:00+03'
and f.scheduled_departure < '2016-10-01 00:00:00+03'
order by loaded_percent asc;

--до индекса Execution Time: 646.321 ms
--после индекса Execution Time: 634.658 ms 

--Вывод: время снизилось, но незначительно -> индекс лучше не использовать для экономии памяти
