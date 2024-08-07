
--See the data

Select * from portfolio..dim_date

select * from portfolio..electric_vehicle_sales_by_state;

select * from portfolio..electric_vehicle_sales_by_maker;



--Lets first break down makers data to geneated usefull tables for insights

--total electric vehicles sold by makers from fiscal years 2022-2024
select  distinct maker, sum(electric_vehicles_sold) as total_ev_sold
from portfolio..electric_vehicle_sales_by_maker
group by  maker


--Sales trend for each maker

select a.maker, b.fiscal_year, b.quarter, a.vehicle_category,sum(a.electric_vehicles_sold) as total_ev_sales
from portfolio..electric_vehicle_sales_by_maker a
join portfolio..dim_date b on a.date =b.date
group by a.maker, b.fiscal_year,b.quarter, a.vehicle_category





-- top 5 makers by ev sold every year from 2022 to 2024
with ct as (
select   a.maker, b.fiscal_year, (sum(a.electric_vehicles_sold) over(partition by b.fiscal_year,a.maker)) as total_ev_sold
from portfolio..electric_vehicle_sales_by_maker a
join portfolio..dim_date b
on a.date = b.date
group by  a.maker, b.fiscal_year, a.electric_vehicles_sold),
rankedSales as (
 select maker,fiscal_year, total_ev_sold, ROW_NUMBER()over (partition by fiscal_year order by total_ev_sold desc) as rank
 from ct
 group by maker, fiscal_year, total_ev_sold
 )
 select maker, fiscal_year, total_ev_sold, rank
 from rankedsales
 where rank <= 5
 order by fiscal_year, rank

 --bottom 5 makers by ev sold every year from 2022 to 2024
 with ct as (
select   a.maker, b.fiscal_year, (sum(a.electric_vehicles_sold) over(partition by b.fiscal_year,a.maker)) as total_ev_sold
from portfolio..electric_vehicle_sales_by_maker a
join portfolio..dim_date b
on a.date = b.date
group by  a.maker, b.fiscal_year, a.electric_vehicles_sold),
rankedSales as (
 select maker,fiscal_year, total_ev_sold, ROW_NUMBER()over (partition by fiscal_year order by total_ev_sold asc) as rank
 from ct
 group by maker, fiscal_year, total_ev_sold
 )
 select maker, fiscal_year, total_ev_sold, rank
 from rankedsales
 where rank <= 5
 order by fiscal_year, rank

 --top and bottom ev sales month 
SELECT *
FROM ( SELECT TOP 1 date, SUM(electric_vehicles_sold) AS total_sales
 FROM portfolio..electric_vehicle_sales_by_maker
GROUP By date
ORDER BY total_sales DESC) AS top_sales
UNION ALL
SELECT *
FROM ( SELECT TOP 1 date, SUM(electric_vehicles_sold) AS total_sales
FROM portfolio..electric_vehicle_sales_by_maker
GROUP BY date
ORDER BY total_sales ASC
) AS bottom_sales;



 --market share of each competitior
 with ct as (select  maker, sum(electric_vehicles_sold) as total_ev_sold 
from portfolio..electric_vehicle_sales_by_maker
group by  maker)
select  maker, total_ev_sold, round((total_ev_sold/sum(total_ev_sold) over()) * 100,2) as market_share
from ct
group by maker, total_ev_sold
order by market_share desc


--Revenue generated for each makers considering avg value of 2W & 4W as Rs85,000 and Rs15,00,000 respectively

with sales as(
select maker, vehicle_category, sum(electric_vehicles_sold) as ev_sales
from portfolio..electric_vehicle_sales_by_maker
group by maker,vehicle_category)
select maker, vehicle_category,ev_sales,
case 
when vehicle_category ='2-Wheelers' then 85000*ev_sales
when vehicle_category ='4-Wheelers' then 1500000*ev_sales
else 0
end as Revenue
from sales
order by vehicle_category, Revenue desc

--compound annual growth rate (CAGR) of makers for their 4W sales
with ct as(
select a.maker,b.fiscal_year, sum(a.electric_vehicles_sold) as total_ev_sold
from portfolio..electric_vehicle_sales_by_maker a
join portfolio..dim_date b on a.date = b.date
where vehicle_category = '4-Wheelers'
group by maker, fiscal_year), ct1 as(
select maker, fiscal_year,total_ev_sold, lag(total_ev_sold) over (partition by maker order by fiscal_year) as previous_sales
from ct)
select maker,fiscal_year, 
case when previous_sales = '0' then 0
else total_ev_sold/previous_sales - 1 
end as CAGR
from ct1

--compound annual growth rate (CAGR) of makers for their sales
with ct as(
select a.maker,b.fiscal_year, sum(a.electric_vehicles_sold) as total_ev_sold
from portfolio..electric_vehicle_sales_by_maker a
join portfolio..dim_date b on a.date = b.date
--where vehicle_category = '2-Wheelers'
group by maker, fiscal_year), ct1 as(
select maker, fiscal_year,total_ev_sold, lag(total_ev_sold) over (partition by maker order by fiscal_year) as previous_sales
from ct), ct2 as(
select maker,total_ev_sold,fiscal_year, 
case when previous_sales = '0' then 0
else round((total_ev_sold/previous_sales - 1 ),2)
end as CAGR
from ct1)
select * from ct2
where CAGR is not null



--One query with every details used this table in designing interactive Tableau dashboard of Makers Performance Analysis
with ct as (select a.maker, b.fiscal_year, b.quarter, a.vehicle_category,sum(a.electric_vehicles_sold) as total_ev_sales
from portfolio..electric_vehicle_sales_by_maker a
join portfolio..dim_date b on a.date =b.date
group by a.maker, b.fiscal_year,b.quarter, a.vehicle_category)
select *, case when vehicle_category = '2-Wheelers' then 80000*total_ev_sales
 else 1500000*total_ev_sales
 end as revenue
 from ct


 --Lets look at States Sales data

--total vehicles sales over the years by states
select  distinct state, sum(electric_vehicles_sold) as total_ev_sold, sum(total_vehicles_sold) as total_vehicle_sold
from portfolio..electric_vehicle_sales_by_state
group by state
order by state

--Sales trend for every States
select  a.state, b.fiscal_year, b.quarter, sum(a.electric_vehicles_sold) as total_ev_sales, sum(a.total_vehicles_sold) as total_sales
from portfolio..electric_vehicle_sales_by_state a
join portfolio..dim_date b on a.date =b.date
group by a.state,b.fiscal_year,b.quarter



 --Pentration rate by states i.e market share of sates for ev sales
 with ct as (select  state, sum(electric_vehicles_sold) as total_ev_sold 
from portfolio..electric_vehicle_sales_by_state
group by  state)
select  state, total_ev_sold, round((total_ev_sold/sum(total_ev_sold) over()) * 100,2) as penetration_rate
from ct
group by state, total_ev_sold
order by  penetration_rate desc

--states with negative penetration rate (decline) in EV sales

with ct as (select  a.state, b.fiscal_year,sum(a.electric_vehicles_sold) as total_ev_sold 
from portfolio..electric_vehicle_sales_by_state a
join portfolio..dim_date b on a.date = b.date
group by  state, fiscal_year),
ct2 as (
select state, fiscal_year, total_ev_sold, round((total_ev_sold/sum(total_ev_sold) over(partition by fiscal_year)) * 100,2) as penetration_rate
from ct
group by state, total_ev_sold, fiscal_year
), ct3 as (
select  state, fiscal_year,total_ev_sold,penetration_rate, 
lag(penetration_rate) over(partition by state order by fiscal_year ) as previous_penetration_rate from ct2

)
select state,fiscal_year, total_ev_sold, penetration_rate, previous_penetration_rate, 
(penetration_rate - previous_penetration_rate) as penetration_rate_change
from ct3
where penetration_rate - previous_penetration_rate < 0
order by  fiscal_year, penetration_rate_change asc



--CAGR of states for total vehicles sales
with ct as(
select a.state,b.fiscal_year, sum(a.total_vehicles_sold) as total_sales, sum(a.electric_vehicles_sold) as ev_sales
from portfolio..electric_vehicle_sales_by_state a
join portfolio..dim_date b on a.date = b.date
where fiscal_year != '2023' 
group by state, fiscal_year), ct1 as(
select state, fiscal_year,total_sales, ev_sales,lag(total_sales) over (partition by state order by fiscal_year) as previous_sales,
lag(ev_sales) over (partition by state order by fiscal_year) as previous_ev_sales
from ct),ct2 as (
select state,
case when previous_sales = '0' then 0
else round((power((total_sales/previous_sales ),0.33) - 1 ),4)*100
end as CAGR_of_total_vehicles,
case when previous_ev_sales ='0' then 0
else round((power((ev_sales/previous_ev_sales),0.33)-1),4)*100
end as CAGR_of_EV
from ct1)
select * from ct2
	where CAGR_of_total_vehicles is not null
order by CAGR_of_total_vehicles desc




--Final query for states data resulted table is used for designing interactive dashboard
with ct as (select a.state, b.fiscal_year, b.quarter, a.vehicle_category,sum(a.electric_vehicles_sold) as total_ev_sales,
sum(a.total_vehicles_sold) as total_sales
from portfolio..electric_vehicle_sales_by_state a
join portfolio..dim_date b on a.date =b.date
group by a.state, b.fiscal_year,b.quarter, a.vehicle_category)
select *, case when vehicle_category = '2-Wheelers' then 85000*total_ev_sales
 else 1500000*total_ev_sales
 end as EV_Revenue, case when  vehicle_category = '2-Wheelers' then 85000*total_sales
 else 1500000*total_sales
 end as Total_Revenue
 from ct

