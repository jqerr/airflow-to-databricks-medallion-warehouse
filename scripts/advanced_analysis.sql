-- change over time trends
-- measure by date dimension: total sales by year; average cost by month; track the business over the time

SELECT 
	YEAR(order_date) as order_year,
	SUM(sales_amount) as total_Sales,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(quantity) as total_quantity
FROM  gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

SELECT 
	DATETRUNC(month,order_date) as order_date,
	SUM(sales_amount) as total_Sales,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(quantity) as total_quantity
FROM  gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)

  -- but won't be sorted correctly cuz it is varchar not integar
SELECT 
	FORMAT(order_date, 'yyyy-MMM') as order_date,
	SUM(sales_amount) as total_Sales,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(quantity) as total_quantity
FROM  gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')
-- cumulative
-- performance 
-- data segmentation
-- part_to_whole_analysis
-- report_customers
-- report_products
