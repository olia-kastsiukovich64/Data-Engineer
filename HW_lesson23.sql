/*
  Задача 1: Создание таблицы с первичным ключом
Создайте новую таблицу Airlines (авиакомпании), которая будет хранить информацию об авиакомпаниях. 
Записать данные туда рандомные.
Таблица должна содержать следующие поля:
- airline_id (идентификатор авиакомпании, целое число, уникальное значение).
- airline_name (название авиакомпании, строка).
- country (страна регистрации авиакомпании, строка).
- Обеспечьте уникальность airline_id !
*/
create table bookings.airlines (
	airline_id serial primary key,
	airline_name varchar (255) not null,
	country varchar (255) not null
);


insert into bookings.airlines (airline_name, country) 
	select concat(
    -- Соединяем два случайных слова из списков
    (array['Global', 'Sky', 'North', 'Pacific', 'Blue', 'Emerald', 'Royal', 'Swift', 'Solar', 'Horizon'])[floor(random() * 10 + 1)], 
    (array['Airways', 'Airlines', 'Jet', 'Connect', 'Fly', 'Transport', 'Express', 'Link', 'Aero', 'Wings'])[floor(random() * 10 + 1)]
    ),
    
    -- Выбираем случайную страну
    (array['Russia', 'United States', 'Germany', 'France', 'Japan', 'China', 'UAE', 'Turkey', 'Brazil', 'Australia', 'Canada', 'Italy'])[floor(random() * 12 + 1)]

from generate_series(1, 100);
   	--floor(random() * 10 + 1) выражение выдает случайное целое число от 1 до 10
	
select * from bookings.airlines

/*
Задача 2: Добавление внешнего ключа
Добавьте поле airline_id в таблицу Flights, чтобы связать каждый рейс с авиакомпанией. 
Создайте внешний ключ на это поле, ссылающийся на таблицу Airlines.
*/ 

alter table bookings.flights
add column airline_id int;

alter table bookings.flights
add constraint fk_flights_airlines
foreign key (airline_id) references bookings.airlines (airline_id);

update bookings.flights
set airline_id = floor(random() * 100 + 1); 

select * from bookings.flights
limit 1000

/*
Задача 3: Частичный индекс для отмененных рейсов
Добавьте поле is_cancelled (логическое значение) в таблицу Flights. 
Создайте частичный индекс для ускорения поиска только отмененных рейсов. 
Сравните результаты до и после создания индекса
*/ 

alter table bookings.flights
add column is_cancelled boolean;

update bookings.flights
set is_cancelled = (random() < 0.2); -- примерно 20% рейсов будут отменены (true)

explain analyze
select 
	flight_id,
	flight_no, 
	is_cancelled
from bookings.flights
where is_cancelled = true;  

--Execution Time: 28.256 ms

create index idx_flights_cancelled 
on bookings.flights (is_cancelled)
where is_cancelled = true; 

explain analyze
select 
	flight_id,
	flight_no, 
	is_cancelled
from bookings.flights
where is_cancelled = true;  

--Execution Time: 13.887 ms - время выполнения запроса сократилось примерно в 2 раза

/*
 Задача 4: Составной индекс для поиска билетов
Создайте составной индекс для ускорения поиска билетов (Tickets) по имени пассажира и номеру билета. 
Сравните результаты до и после создания индекса.
 */

explain analyze
select ticket_no, passenger_name, contact_data
from bookings.tickets
where passenger_name = 'OLGA YUDINA';

--Execution Time: 117.297 ms

м

explain analyze
select ticket_no, passenger_name, contact_data
from bookings.tickets
where passenger_name = 'OLGA YUDINA';

--Execution Time: 4.820 ms - время сократилось более чем в 20 раз

/*Оптимизация JOIN-запроса между рейсами и аэропортами
 */
EXPLAIN ANALYZE
SELECT f.flight_id, f.flight_no, a.airport_name
FROM bookings.flights f
JOIN bookings.airports a ON f.departure_airport = a.airport_code
WHERE a.airport_name = 'Домодедово';

--Execution Time: 31.843 ms

-- создаем индекс на departure_airport так как джойним табличку по этому ключу
create index idx_flights_departure_airport 
on bookings.flights (departure_airport);


EXPLAIN ANALYZE
SELECT f.flight_id, f.flight_no, a.airport_name
FROM bookings.flights f
JOIN bookings.airports a ON f.departure_airport = a.airport_code
WHERE a.airport_name = 'Домодедово';

-- Execution Time: 7.700 ms 


