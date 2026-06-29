-- database explortaion: to understand the database stucture
SELECT DISTINCT
category
FROM gold.dim_products

-- EXPLORE ALL OBJECTS IN THE DATABASE
SELECT * FROM INFORMATION_SCHEMA.TABLES 

-- EXPLORE ALL COLUMNS IN THE DATABASE
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

/* 
dimension exploration
distinct [dimension]: understand the granuality of the dimensions
*/
-- explore where the customers come from
SELECT DISTINCT country FROM gold.dim_customers
-- explore the categories the major divisionsb  => understand the dimensions
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3  -- sort the data by these three info

/*
Date Exploration
the bounrty of the date? the timespan
MIN/MAX/ DATEDIFF [date dimension]
*/
SELECT 
MIN(order_date) AS first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales
--find the youngeset and the oldest customer
SELECT 
MIN(birthdate) AS oldest_birhdate,
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers


/*
Measure exploration
find the key metric of the business: total revenue = big number
*/
-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales
-- Find the average selling price
SELECT AVG(price) AS avg_price FROM gold.fact_sales
-- Find the Total number of Orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales
-- Find the total number of products
SELECT COUNT(product_name) AS total_products FROM gold.dim_products
SELECT COUNT(DISTINCT product_name) AS total_products FROM gold.dim_products
-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;
-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products', COUNT(product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers', COUNT(customer_key) FROM gold.dim_customers





