use SQL_Project_1;

create table sales(
transaction_id varchar(50),
customer_id varchar(50),
customer_name varchar(150),
customer_age int,
gender varchar(50),
product_id varchar(50),
product_name varchar(150),
product_category varchar(150),
quantiy int,
prce decimal(10,2),
payment_method varchar(150),
purchase_date date,
time_of_purchase time,
status varchar(50)
);

set dateformat dmy
bulk insert sales
from 'D:\Dataset\Kaggle\sales_1.csv'
with(
	firstrow = 2,
	fieldterminator = ',',
	rowterminator = '\n'
	);

select top 10 * from sales;
select * into sales_duplicate from sales



--data cleaning
--step 1:
select transaction_id from sales
group by transaction_id
having count(transaction_id) > 1;

with cte as
(select *,
row_number() over (partition by transaction_id order by transaction_id) as row_num
from sales)

--delete from cte
--where row_num = 2

select * from cte
where transaction_id in ('TXN240646', 'TXN342128', 'TXN855235', 'TXN981773');

--step 2: rename headers
exec sp_rename 'sales.quantiy','quantity','column';
exec sp_rename 'sales.prce','price','column';

--step 3: to check data type
select 
	table_name,
	column_name,
	data_type
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'sales';

-- step 4: to check null values
DECLARE @SchemaName SYSNAME = 'dbo';
DECLARE @TableName SYSNAME = 'sales';
DECLARE @SQL NVARCHAR(MAX);

SELECT @SQL = STRING_AGG(
    CAST(
        N'SELECT ''' + REPLACE(name, '''', '''''') + N''' AS ColumnName, ' +
        N'COUNT(*) - COUNT(' + QUOTENAME(name) + N') AS NullCount ' +
        N'FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName)
        AS NVARCHAR(MAX)
    ),
    N' UNION ALL '
)
FROM sys.columns
WHERE object_id = OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName));

--Execcute the dynamic SQL
EXEC sp_executesql @SQL;

--treating null values

select * from sales
where transaction_id is null
or customer_id is null
or customer_name is null
or customer_age is null
or gender is null
or payment_method is null
or purchase_date is null
or time_of_purchase is null
or status is null;

--delete from sales
--where transaction_id is null;

select * from sales
where customer_name = 'Ehsaan Ram';

update sales
set customer_id = 'CUST9494'
where transaction_id = 'TXN977900'

select * from sales
where customer_name = 'Damini Raju';

update sales
set customer_id = 'CUST1401'
where transaction_id = 'TXN985663'

select * from sales
where customer_id = 'CUST1003';

update sales
set customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
where transaction_id = 'TXN432798';

select * from sales

--step 5: Data Cleaning

select distinct gender from sales

update sales
set gender = 'M'
where gender = 'Male';

update sales
set gender = 'F'
where gender = 'Female';

select distinct payment_method from sales

update sales
set payment_method = 'Credit Card'
where payment_method = 'CC';

-- Data Analysis
--Q1. What are the top 4 best-selling products by total quantity sold?

select distinct status from sales

select top 4 product_name, sum(quantity) as total_quantity
from sales
where status = 'delivered' -- sales status has pending, cancel, returned & delivered
group by product_name
order by sum(quantity) DESC

--Q2. Which product generate the highest revenue?

select top 1 product_name, 
format(sum(price * quantity),'N2') as total_sales
from sales
where status = 'delivered'
group by product_name
order by sum(price * quantity) DESC

-- Q3.What time of the day has the highest number of purchase?
select * from sales
--Note: shopping hours contain all the status (returned, pending, cancelled, delivered)
select
	case
		when datepart(hour, time_of_purchase) between 0 and 5 then 'Night'
		when datepart(hour, time_of_purchase) between 6 and 11 then 'Morning'
		when datepart(hour, time_of_purchase) between 12 and 17 then 'Afternoon'
		when datepart(hour, time_of_purchase) between 18 and 23 then 'Evening'
	end as time_of_day,
	count (*) as total_purchase
	from sales
	group by
	case
		when datepart(hour, time_of_purchase) between 0 and 5 then 'Night'
		when datepart(hour, time_of_purchase) between 6 and 11 then 'Morning'
		when datepart(hour, time_of_purchase) between 12 and 17 then 'Afternoon'
		when datepart(hour, time_of_purchase) between 18 and 23 then 'Evening'
	end
	order by total_purchase DESC

-- Q4. Who are the top 5 repeat customers by order count or spend?

select top 5 customer_id, customer_name, count(*) as total_repeatation
from sales
where status = 'delivered'
group by customer_id, customer_name
having count(*) > 1
order by count(*) DESC;

-- Q5. Which product category generate the highest revenue?

select top 5 product_category, 
	format(sum(price*quantity),'N0') as total_revenue
from sales
where status = 'delivered'
group by product_category
order by sum(price*quantity) DESC

-- Q6. What is the return and cancellation rate for each product category?

--cancelled rate
select product_category, 
	format(count(case when status = 'cancelled' then 1 end)*100.0/count(*),'N1')+' %' as cancel_rate
from sales
group by product_category
order by cancel_rate DESC

--returned rate
select product_category,
	format(count(case when status = 'returned' then 1 end)*100.0/count(*), 'N1')+ ' %' as return_rate
from sales
group by product_category
order by return_rate DESC

-- Q7. What is the most preferred payment mode across transactions?

select payment_method, count(*) as total_payment_mode, 
cast(cast(count(*)*100.0/sum(count(*)) over() as decimal(5,2)) as varchar(10)) + ' %' as rate_payment_mode
from sales
where status = 'delivered'  --if you want to know only for delivered status
group by payment_method
order by count(*) DESC

-- Q8. How does purchasing behavior differ across age groups?
select * from sales

select min(customer_age), max(customer_age)
from sales
select
	case
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		Else '51+'
		end as age_group,
		format(sum(price*quantity),'N2') as total_revenue from sales
	
	group by (case
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		Else '51+'
		end)
	order by sum(price*quantity) DESC

-- Q9. How does sales performance trend month over month?
select * from sales
-- Method 1:
select 
	format(purchase_date,'yyyy-MM') as monthly,
	format(sum(price * quantity),'N2') as total_monthly_revenue
	from sales
	where status = 'delivered'
	group by format(purchase_date,'yyyy-MM')

-- Method 2:
select 
	year(purchase_date) as yearly,
	month(purchase_date) as monthly,
	format(sum(price * quantity),'N2') as total_monthly_revenue
	from sales
	where status = 'delivered'
	group by year(purchase_date),month(purchase_date)
	Order by sum(price * quantity) DESC

-- Q10. Do certain genders purchase specific product categories more frequently?
select * from sales
select distinct gender from sales

-- Method 1:
select gender,product_category,
count(product_category) as total_prod_category
from sales
where status = 'delivered'
group by gender,product_category
order by count(product_category) DESC
--Method 2:

select * from
(select gender, product_category
from sales
where status = 'delivered') as source_table
pivot
	(count(gender)
	for gender in ([M],[F])
	) as pivot_table
order by product_category

