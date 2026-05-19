--Задача 1: Рейсы с задержкой больше средней (через CTE или подзапрос)
--Найдите рейсы, задержка которых превышает среднюю задержку по всем рейсам.
--Использовать только таблицу flights

select 
    f.flight_id,
    round(extract(epoch from (f.actual_departure - f.scheduled_departure)) / 60, 2) as flight_delay
from flights f
cross join (
    select round(avg(extract(epoch from (actual_departure - scheduled_departure)) / 60), 2) as global_avg
    from flights
) as avg_delay 
where 
    f.actual_departure is not null
    and round(extract(epoch from (f.actual_departure - f.scheduled_departure)) / 60, 2) > avg_delay.global_avg
order by 2 desc;


--Задача 2: Создать VIEW для статистики по аэропортам
-- Создайте представление, которое показывает для каждого аэропорта:
-- Количество вылетов
-- Количество направлений
-- Среднюю задержку рейсов

create or replace view airport_statistics_v as
select 
    a.airport_code,
    a.airport_name,
    count(f.flight_id) as departures_count,
    count(distinct f.arrival_airport) as directions_count,
    round(avg(extract(epoch from (f.actual_departure - f.scheduled_departure)) / 60), 2) as avg_delay_minutes
from flights f
right join airports a on f.departure_airport = a.airport_code
group by 
    a.airport_code, 
    a.airport_name;

--Задача 3: Создать функцию get_airport_info(airport_code text) которая по коду аэропорта выводит его название, 
--если его нету, то вывести что аэропорт не найден.

create or replace function get_airport_info(p_airport_code text)
returns text as $$
declare
    v_airport_name text;
begin
    select airport_name into v_airport_name 
    from airports 
    where airport_code = p_airport_code;
    if not found then
        return 'Аэропорт не найден';
    end if;
    return v_airport_name;
end;
$$ language plpgsql;
