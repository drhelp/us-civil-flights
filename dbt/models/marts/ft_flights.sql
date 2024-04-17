{{ config(
    materialized='table',
    partition_by={
      "field": "Flight_Date",
      "data_type": "date",
      "granularity": "month"
    },
    cluster_by=['Airline','Tail_Number']
)}}

with stg as (
    select *
    from {{ref("stg_us_flights")}}
)
select
    FlightDate as Flight_Date,
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
from stg