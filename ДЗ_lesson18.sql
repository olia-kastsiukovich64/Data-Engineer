--Найти рейсы в бизнес-классе, вылетающие из Москвы
select
	f.flight_no,
	f.departure_airport,
	f.arrival_airport 
from flights f 
left join airports a on a.airport_code = f.departure_airport
left join seats s  on s.aircraft_code = f.aircraft_code 
where a.city = 'Москва' and s.fare_conditions = 'Business'
group by 
	f.flight_no,
	f.departure_airport,
	f.arrival_airport 
;

--Найти самолеты, которые никогда не использовались в рейсах

select
	a2.aircraft_code, 
	a2.model
from aircrafts a2
left join flights f on f.aircraft_code = a2.aircraft_code
where f.flight_id  is null 

--можно посчитать сколько раз использовался каждый самолет в рейсах


select
	a2.aircraft_code, 
	a2.model,
	count(f.flight_id) as flights_count
from aircrafts a2
left join flights f on f.aircraft_code = a2.aircraft_code
group by 
	a2.aircraft_code, 
	a2.model
order by flights_count asc 

