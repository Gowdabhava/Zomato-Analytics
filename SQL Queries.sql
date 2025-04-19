
Use Zomato_Restaurant_analysis;
#----------------------------------------------------------------------------------------------------

#1. Adding date column with fulldate
alter table main_table add column Date_opened date;
update main_table 
SET date_opened= STR_TO_DATE(CONCAT(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')), '%Y-%m-%d');

#calendar query with KPIs mentioned:
create table calendar as(
select date_opened,year,month ,monthname(date_opened) as Monthname,quarter(date_opened) as Quarter,
concat(year,'-',LPAD(month, 2, '0')) as YYYY_MM,weekday(date_opened) as Weekday, dayname(date_opened) as weekday_name,
CASE WHEN MONTH(date_opened) >= 4 THEN MONTH(date_opened) - 3
ELSE MONTH(date_opened) + 9 
END AS financial_month,
CASE WHEN MONTH(date_opened) >= 4 THEN FLOOR((MONTH(date_opened) - 3) / 3) + 1
ELSE FLOOR((MONTH(date_opened) + 9) / 3) + 1
END AS financial_quarter
from main_table);

select * from Calendar;
#----------------------------------------------------------------------------------------------------

#2. Convert the Average cost for 2 column into USD dollars and INR :
select m.restaurantname,round((m.average_cost_for_two*c.usd_rate),2) as avg_cost_in_usd, 
round(((m.average_cost_for_two*c.usd_rate)/.012),2) as avg_cost_in_inr
from main_table m join currency c
on m.currency=c.currency;
#----------------------------------------------------------------------------------------------------

#3. Find the Number of Resturants based on City and Country.
select c.countryname,m.city,count(m.restaurantid) as restaurant_count 
from main_table m join country c
on m.countrycode=c.countryid
group by 1,2
order by 3 desc;
#----------------------------------------------------------------------------------------------------

#4. Number of Resturants opening based on Year , Quarter , Month
select c.year,c.quarter,c.monthname,count(m.restaurantid) as Rest_count
from main_table m join calendar c 
on m.date_opened=c.date_opened
group by 1,2,3
order by 4 desc;
#----------------------------------------------------------------------------------------------------

#5. Count of Resturants based on Rating bucket
select count(restaurantname) as rest_count,
case when rating<=1 then "0-1"
when rating>1 and rating<=2 then "1.1-2"
when rating>2 and rating<=3 then "2.1-3"
when rating>3 and rating<=4 then "3.1-4"
else "4.1-5"
end as rating_bucket
from main_table
group by 2
order by rating_bucket;
#----------------------------------------------------------------------------------------------------

#6. Count of Resturants based on Avg Price bucket
select count(m.restaurantname) as rest_count,
case when ((m.average_cost_for_two*c.usd_rate)/.012)<=300 then "0-300"
when ((m.average_cost_for_two*c.usd_rate)/.012)>300 and ((m.average_cost_for_two*c.usd_rate)/.012)<=600 then "301-600"
when ((m.average_cost_for_two*c.usd_rate)/.012)>600 and ((m.average_cost_for_two*c.usd_rate)/.012)<=1000 then "601-1000"
else "Above 1000"
end as cost_bucket
from main_table m join currency c 
on m.currency=c.currency
group by 2
order by cost_bucket;
#----------------------------------------------------------------------------------------------------

#7. Percentage of Resturants based on "Has_Table_booking"
SELECT Has_Table_Booking,COUNT(*) AS restaurant_count,
concat(ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main_table)), 2),"%") AS percentage
FROM main_table
GROUP BY Has_Table_Booking;
#----------------------------------------------------------------------------------------------------

#8. Percentage of Resturants based on "Has_online_delivery"
select has_online_delivery,count(*) as rest_count,
concat(round((count(*)*100)/(select count(*) from main_table),2),"%") as percentage
from main_table
group by 1;

#----------------------------------------------------------------------------------------------------

#9. Top 5 ranking cuisines based on restaurant count
select * from
(select cuisines, count(restaurantid) as rest_count , 
dense_rank() over (order by count(restaurantid) desc) as ranks
from main_table
group by 1) as cuisines
where ranks<=5;
#----------------------------------------------------------------------------------------------------

#10. Top 10 restaurants based on votes
select * from
(select restaurantname, sum(votes) as votes,
dense_rank() over (order by sum(votes) desc) as ranks
from main_table
group by 1) as votes
where ranks<=10;
#----------------------------------------------------------------------------------------------------
#11. Restaurants, Cuisines, Country, City, Votes, Average rating, Total Cost (INR), Total Cost(USD)
SELECT  
COUNT(RestaurantID) AS Total_Restaurant,  
COUNT(DISTINCT Cuisines) AS Total_Cuisines,  
COUNT(DISTINCT CountryCode) AS Total_Country,  
COUNT(DISTINCT City) AS Total_City,  
CONCAT(ROUND(SUM(ROUND(Votes)) / 1000), 'K') AS Total_Votes,  
AVG(Rating) AS Avg_Rating,  
CONCAT(ROUND(SUM(ROUND(Indian_RupeesCost)) / 1000), 'K') AS Total_Cost_in_Rupees,  
CONCAT(ROUND(SUM(ROUND(USDCost)) / 1000), '$') AS Total_Cost_in_USD  
FROM main;

#----------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------


