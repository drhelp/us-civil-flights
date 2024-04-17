with src as (
    select * from {{source('us_civil_flights_sources','src_us_flights_2023')}}
)
select 
    FlightDate,
	Day_Of_Week,
	Airline,
	Tail_Number,
	Dep_Airport,
	Dep_CityName,
	DepTime_label,
	Dep_Delay,
	Dep_Delay_Tag,
	Dep_Delay_Type,
	Arr_Airport,
	Arr_CityName,
	Arr_Delay,
	Arr_Delay_Type,
	Flight_Duration,
	Distance_type,
	Delay_Carrier,
	Delay_Weather,
	Delay_NAS,
	Delay_Security,
	Delay_LastAircraft,
	Manufacturer,
	Model,
	Aicraft_age
from src