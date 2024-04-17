with src as (
    select * from {{source("us_civil_flights_sources",'src_weather_meteo_by_airport')}}
)
SELECT
	`time` as flight_date,
	tavg,
	tmin,
	tmax,
	prcp,
	snow,
	wdir,
	wspd,
	pres,
	airport_id
FROM
	src