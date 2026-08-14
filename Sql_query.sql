select * from swiggy_data;

-- Data Cleaning and Validation


-- Check Null Value
SELECT 
SUM(case when State is null then 1 else 0 end) as null_state ,
SUM(case when City is null then 1 else 0 end ) as null_city ,
SUM(case when Order_Date is null then 1 else 0 end ) as null_order_date ,
SUM(case when Restaurant_Name is null then 1 else 0 end ) as null_restaurant,
SUM(case when Location is null then 1 else 0 end ) as null_location ,
SUM(case when Category is null then 1 else 0 end ) as null_category ,
SUM(case when Dish_Name is null then 1 else 0 end) as null_dish ,
SUM(case when Price_INR is null then 1 else 0 end) as null_price ,
SUM(case when Rating is null then 1 else 0 end ) as null_rating ,
SUM(case when Rating_Count is null then 1 else 0 end ) as null_rating_count 
FROM swiggy_data ;

-- Check Blank or Empty String
select * from swiggy_data
where State = '' or City = '' or Restaurant_Name = '' 
or Location = '' or Category = '' or Dish_Name = '' ;

-- Check Duplicate Detection
SELECT 
State , City , Order_Date , Restaurant_Name , Location , Category , Dish_Name , Price_INR , Rating , Rating_Count ,
count(*) as count_All
FROM swiggy_data  
Group BY 
State , City , Order_Date , Restaurant_Name , Location , Category , Dish_Name , Price_INR , Rating , Rating_Count
HAVING count(*)>1 ;

-- Delete Duplication
WITH CTE as (
select * , 
ROW_NUMBER() OVER(partition by State , City , Order_Date , Restaurant_Name , Location , 
Category , Dish_Name , Price_INR , Rating , Rating_Count order by (select null) ) as rn
from swiggy_data 
)

Delete FROM CTE where rn > 1


-------x------------------x-------------------x------------------x------------


-- Creating Schema 

-- Date Table
create table dim_date(
date_id int IDENTITY(1,1) primary key ,
Full_Date date ,
Year int,
Month int,
Month_Name varchar(20),
Quarter INT ,
Day INT,
Week INT
)

select * from dim_date ;

-- Location Table dim_location
create table dim_location(
location_id INT IDENTITY(1,1) primary key ,
State varchar(100) ,
City varchar(100),
Location varchar(200)
);

-- Restaurant Table dim_restaurant
create table dim_restaurant(
 restaurant_id INT Identity(1,1) primary key,
 Restaurant_Name varchar(200)
);

-- dim_category table
create table dim_category(
 category_id int identity(1,1) primary key ,
 Category varchar(200)
);

-- dim_dish table
create table dim_dish(
 dish_id int identity(1,1) primary key ,
 Dish_Name varchar(200)
);

-- fact_swiggy_orders table
create table fact_swiggy_orders(
 order_id int identity(1,1) primary key ,

 Price_INR Decimal(10,2) ,
 Rating Decimal(4,2),
 Rating_Count int ,

 date_id int ,
 location_id int ,
 restaurant_id int ,
 category_id int,
 dish_id int ,

 FOREIGN KEY (date_id) references dim_date(date_id) ,
 FOREIGN KEY (location_id) references dim_location(location_id) ,
 foreign key (restaurant_id) references dim_restaurant(restaurant_id) ,
 foreign key (category_id) references dim_category(category_id) ,
 foreign key (dish_id) references dim_dish(dish_id)
);

select * from fact_swiggy_orders;


-------x------------------x-------------------x------------------x------------


-- Insert Data IN TABLES 
-- dim_date
insert into dim_date(FULL_Date , Year , Month , Month_Name , Quarter , Day , Week)
select Distinct 
Order_Date,
Year(Order_Date),
MONTH(Order_Date),
DATENAME(Month , Order_Date),
DATEPART(QUARTER , Order_Date),
Day(Order_Date),
DATEPART(WEEK , Order_Date)
from swiggy_data
where Order_Date is not null ;

select * from dim_date order by Full_Date ;

-- dim_location
insert into dim_location(State , City , Location)
select distinct State , City , Location
from swiggy_data

select * from dim_location ;

-- dim_restaurant
insert into dim_restaurant (Restaurant_Name)
select DISTINCT Restaurant_Name
FROM swiggy_data ;

-- dim_category
INSERT INTO dim_category(Category)
SELECT DISTINCT Category
FROM swiggy_data ;

-- dim_dish
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT Dish_Name
FROM swiggy_data;

select * from fact_swiggy_orders ;

-- fact_swiggy_orders
insert into fact_swiggy_orders 
( 
 Price_INR ,
 Rating , 
 Rating_Count , 
 date_id, 
 location_id ,
 restaurant_id ,
 category_id ,
 dish_id 
 )
 select 
 s.Price_INR ,
 s.Rating ,
 s.Rating_Count,
 dd.date_id,
 dl.location_id ,
 dr.restaurant_id ,
 dc.category_id,
 dsh.dish_id 
 from swiggy_data s
 join dim_date as dd on dd.Full_Date  = s.Order_Date
 join dim_location as dl on dl.State = s.State and dl.City = s.City and s.Location = dl.Location 
 join dim_restaurant as dr on  dr.Restaurant_Name = s.Restaurant_Name
 join dim_category as dc on dc.Category = s.Category
 join dim_dish as dsh on dsh.Dish_Name = s.Dish_Name 


 -- Built KPI's ---->>>>>

 -- Total Orders
  select 
   count(*) as Total_Orders 
 from fact_swiggy_orders ;

 -- Total Revenue (INR Millions)
  select 
   Format(sum(CONVERT(float , fs.Price_INR))/1000000,'N2') + ' INR Million'
   as Total_Revenue
 from fact_swiggy_orders as fs
 

 -- Avg Rating
  select avg(fs.Rating) as Avg_Rating 
  from fact_swiggy_orders as fs ;

 -- Avg Dish Price
 select 
   Format(avg(fs.Price_INR),'N2') + ' INR' as Avg_Dish_Price
 from fact_swiggy_orders as fs ;


 
-------x------------------x-------------------x------------------x------------

 -- Deep-Dive Business Analysis ---->>>>>
 -- Date Based Analysis ---->>>>>

 -- 1. Monthly Trend (Total Revenue and Total Orders )

 select * from 
 (
 select
 dd.Year ,
 dd.Month ,
 dd.Month_Name ,
 count(*) as Monthly_Orders ,
 format(sum(convert(float , fso.Price_INR))/1000000 , 'N2') + ' INR Millon' as Monthly_Revenue 
 from fact_swiggy_orders as fso
 join dim_date as dd
 on dd.date_id = fso.date_id 
 group by dd.Year , dd.Month , dd.Month_Name ) 
 as result
 -- order by monthly order count
 order by result.Monthly_Orders desc;



 -- 2. Quartely Trend (Quartely Revenue and Orders )

 select 
 count(*) as Quartely_Orders ,
 Format(sum(convert(float , fso.Price_INR))/1000000 , 'N2') as Quartely_Trend, 
 dd.Quarter
 from fact_swiggy_orders as fso
 join dim_date as dd on dd.date_id = fso.date_id
 group by dd.Quarter 
 order by count(*) desc;


 -- 3. Year-wise growth
 select 
 dd.Year , 
 count(*) as Year_Orders
 from fact_swiggy_orders as fso
 join dim_date as dd 
 on dd.date_id = fso.date_id 
 group by dd.Year ;
 
 -- 4. Day-of-Week Trend (Revenue and Orders )
 select  
 DateName(WEEKDAY,dd.Full_Date) as Day_Name ,
 count(*) as Total_Orders ,
 sum(Price_INR) as Total_Revenue
 from fact_swiggy_orders as fso
 join dim_date as dd on dd.date_id = fso.date_id
 group by DateName(WEEKDAY,dd.Full_Date) 
 order by DateName(WEEKDAY,dd.Full_Date);



-------x------------------x-------------------x------------------x------------

 -- Location Based Analysis ---->>>>>

 -- 1. Top 10 cities by order volume
 select TOP 10
 dl.State ,
 dl.City ,
 count(*) as Order_Count
 from fact_swiggy_orders as fso 
 join dim_location as dl
 on dl.location_id = fso.location_id 
 group by dl.City , dl.State
 Order by count(*) desc ;

 -- 2. Revenue contribution by state 
 select 
 dl.State ,
 format(sum(fso.Price_INR)/1000000 , 'N2') + ' INR Million' as Total_Revenue 
 from fact_swiggy_orders as fso 
 join dim_location as dl 
 on fso.location_id = dl.location_id
 Group by dl.State ;

 
-------x------------------x-------------------x------------------x------------

 -- Food Performance ---->>>>>

 -- 1. Top 10 restaurants by orders 
 select Top 10
 fs.restaurant_id ,
 dr.Restaurant_Name ,
 count(*) as Total_Orders ,
 sum(fs.Price_INR) as Total_Revenue
 from fact_swiggy_orders as fs
 join dim_restaurant as dr
 on dr.restaurant_id = fs.restaurant_id 
 group by fs.restaurant_id , dr.Restaurant_Name
 order by sum(fs.Price_INR) desc;


 -- 2. Top categories (Indian , Chinese etc)

 select 
 dc.Category ,
 count(*) as Total_Orders ,
 sum(fs.Price_INR)as Total_Revenue
 from fact_swiggy_orders as fs
 join dim_category as dc
 on dc.category_id = fs.category_id
 group by dc.Category
 order by count(*) desc;

 -- 3. Most Ordered dishes 
 select Top 10
 dd.Dish_Name ,
 count(*) as Total_Orders
 from fact_swiggy_orders  as fs
 join dim_dish as dd 
 on dd.dish_id = fs.dish_id
 group by dd.Dish_Name
 order by count(*) desc ;

 -- 4. Cuisine Performance -(Orders + Avg Rating)
 select 
 c.Category ,
 count(*) as Total_Orders ,
 Avg(fs.Rating) as Avg_Rating
 from fact_swiggy_orders as fs 
 join dim_category as c 
 on fs.category_id = c.category_id
 group by c.Category
 order by Total_Orders desc;

 
-------x------------------x-------------------x------------------x------------


 -- Customer Spending insights ---->>>>>

 select
 count(*)  as Total_orders,
 case 
   when Price_INR between 0 and 99 then 'Under 100' 
   when Price_INR between 100 and 199 then '100-199' 
   when Price_INR between 200 and 299 then '200-299'
   when Price_INR between 300 and 499 then '300-499'
   else '500+'
 end as Customer_Spend 
 from fact_swiggy_orders
 GROUP BY
 case 
   when Price_INR between 0 and 99 then 'Under 100' 
   when Price_INR between 100 and 199 then '100-199' 
   when Price_INR between 200 and 299 then '200-299'
   when Price_INR between 300 and 499 then '300-499'
   Else '500+'
 end 
 order by Total_orders desc;



 -------x------------------x-------------------x------------------x------------


 -- Rating Based Analysis ---->>>>>

 select 
 rating ,
 count(*) as rating_count 
 from fact_swiggy_orders
 group by rating 
 order by count(*) desc ;

