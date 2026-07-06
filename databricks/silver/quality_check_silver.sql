-- Databricks notebook source
SELECT assert_true(COUNT(*) = 0, 'crm_cust_info: null/duplicate cst_id')
FROM (SELECT cst_id FROM datawarehouse.silver.crm_cust_info GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL);

SELECT assert_true(COUNT(*) = 0, 'crm_cust_info: unwanted spaces in cst_key')
FROM datawarehouse.silver.crm_cust_info WHERE cst_key != TRIM(cst_key);

SELECT assert_true(COUNT(*) = 0, 'crm_prd_info: null/duplicate prd_id')
FROM (SELECT prd_id FROM datawarehouse.silver.crm_prd_info GROUP BY prd_id HAVING COUNT(*) > 1 OR prd_id IS NULL);

SELECT assert_true(COUNT(*) = 0, 'crm_prd_info: unwanted spaces in prd_nm')
FROM datawarehouse.silver.crm_prd_info WHERE prd_nm != TRIM(prd_nm);

SELECT assert_true(COUNT(*) = 0, 'crm_prd_info: null/negative prd_cost')
FROM datawarehouse.silver.crm_prd_info WHERE prd_cost < 0 OR prd_cost IS NULL;

SELECT assert_true(COUNT(*) = 0, 'crm_prd_info: prd_end_dt before prd_start_dt')
FROM datawarehouse.silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;

SELECT assert_true(COUNT(*) = 0, 'crm_sales_details: order date after ship/due date')
FROM datawarehouse.silver.crm_sales_details WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

SELECT assert_true(COUNT(*) = 0, 'crm_sales_details: sales != quantity * price')
FROM datawarehouse.silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

SELECT assert_true(COUNT(*) = 0, 'erp_cust_az12: birthdate out of range')
FROM datawarehouse.silver.erp_cust_az12 WHERE bdate < '1900-01-01' OR bdate > current_date();

SELECT assert_true(COUNT(*) = 0, 'erp_px_cat_g1v2: unwanted spaces')
FROM datawarehouse.silver.erp_px_cat_g1v2 WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);