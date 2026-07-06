-- Databricks notebook source
CREATE OR REPLACE TABLE datawarehouse.bronze.crm_cust_info AS
SELECT * FROM read_files('s3://jq-dw-medallion/raw/crm/cust_info.csv', format => 'csv', header => true);

CREATE OR REPLACE TABLE datawarehouse.bronze.crm_prd_info AS
SELECT * FROM read_files('s3://jq-dw-medallion/raw/crm/prd_info.csv', format => 'csv', header => true);

CREATE OR REPLACE TABLE datawarehouse.bronze.crm_sales_details AS
SELECT * FROM read_files('s3://jq-dw-medallion/raw/crm/sales_details.csv', format => 'csv', header => true);

CREATE OR REPLACE TABLE datawarehouse.bronze.erp_cust_az_12 AS
SELECT * FROM read_files('s3://jq-dw-medallion/raw/erp/CUST_AZ12.csv', format => 'csv', header => true);

CREATE OR REPLACE TABLE datawarehouse.bronze.erp_loc_a_101 AS
SELECT * FROM read_files('s3://jq-dw-medallion/raw/erp/LOC_A101.csv', format => 'csv', header => true);

CREATE OR REPLACE TABLE datawarehouse.bronze.erp_px_cat_g_1_v_2 AS
SELECT * FROM read_files('s3://jq-dw-medallion/raw/erp/PX_CAT_G1V2.csv', format => 'csv', header => true);