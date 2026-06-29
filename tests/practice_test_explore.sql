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
