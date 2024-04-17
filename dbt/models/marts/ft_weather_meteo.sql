with stg as (
    select * from {{ref("stg_weather_meteo")}}
)
SELECT
    flight_date as Flight_Date,
	tavg as Temp_Avg,
	tmin as Temp_Min,
	tmax as Temp_Max,
	prcp as Precipitation,
	snow as Snow_Depth,
	wdir as Wind_Direction ,
	wspd as Wind_Speed,
	pres as Air_Pressure ,
	airport_id as Airport_Id
from stg