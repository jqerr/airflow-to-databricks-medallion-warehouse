-- Databricks notebook source
SELECT assert_true(COUNT(*) = 0, 'dim_customers: duplicate customer_key')
FROM (SELECT customer_key FROM datawarehouse.gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1);

SELECT assert_true(COUNT(*) = 0, 'dim_products: duplicate product_key')
FROM (SELECT product_key FROM datawarehouse.gold.dim_products GROUP BY product_key HAVING COUNT(*) > 1);

SELECT assert_true(COUNT(*) = 0, 'fact_sales: orphaned customer/product key')
FROM datawarehouse.gold.fact_sales f
LEFT JOIN datawarehouse.gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN datawarehouse.gold.dim_products p ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;