import pendulum
from airflow.decorators import dag, task
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook

@dag(
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2026, 1, 1, tz="Australia/Brisbane"),
    catchup=False,
)
def bronze_silver_pipeline():

    @task
    def load_bronze():
        hook = MsSqlHook(mssql_conn_id="mssql_datawarehouse")
        hook.run("EXEC bronze.load_bronze;", autocommit=True)

    @task
    def load_silver():
        hook = MsSqlHook(mssql_conn_id="mssql_datawarehouse")
        hook.run("EXEC silver.load_silver;", autocommit=True)

    @task
    def quality_check_silver():
        hook = MsSqlHook(mssql_conn_id="mssql_datawarehouse")
        checks = {
            "crm_cust_info: null/duplicate cst_id": """
                SELECT cst_id, COUNT(*) FROM silver.crm_cust_info
                GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL
            """,
            "crm_cust_info: unwanted spaces in cst_key": """
                SELECT cst_key FROM silver.crm_cust_info
                WHERE cst_key != TRIM(cst_key)
            """,
            "crm_prd_info: null/duplicate prd_id": """
                SELECT prd_id, COUNT(*) FROM silver.crm_prd_info
                GROUP BY prd_id HAVING COUNT(*) > 1 OR prd_id IS NULL
            """,
            "crm_prd_info: unwanted spaces in prd_nm": """
                SELECT prd_nm FROM silver.crm_prd_info
                WHERE prd_nm != TRIM(prd_nm)
            """,
            "crm_prd_info: null/negative prd_cost": """
                SELECT prd_cost FROM silver.crm_prd_info
                WHERE prd_cost < 0 OR prd_cost IS NULL
            """,
            "crm_prd_info: prd_end_dt before prd_start_dt": """
                SELECT * FROM silver.crm_prd_info
                WHERE prd_end_dt < prd_start_dt
            """,
            "crm_sales_details: order date after ship/due date": """
                SELECT * FROM silver.crm_sales_details
                WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt
            """,
            "crm_sales_details: sales != quantity * price": """
                SELECT sls_sales, sls_quantity, sls_price FROM silver.crm_sales_details
                WHERE sls_sales != sls_quantity * sls_price
                   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
                   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
            """,
            "erp_cust_az12: birthdate out of range": """
                SELECT DISTINCT bdate FROM silver.erp_cust_az12
                WHERE bdate < '1900-01-01' OR bdate > GETDATE()
            """,
            "erp_px_cat_g1v2: unwanted spaces": """
                SELECT * FROM silver.erp_px_cat_g1v2
                WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)
            """,
        }
        failures = []
        for name, sql in checks.items():
            rows = hook.get_records(sql)
            if rows:
                failures.append(f"- {name}: {len(rows)} bad row(s)")
        if failures:
            raise ValueError("Silver quality checks failed:\n" + "\n".join(failures))

    @task
    def quality_check_gold():
        hook = MsSqlHook(mssql_conn_id="mssql_datawarehouse")
        checks = {
            "dim_customers: duplicate customer_key": """
                SELECT customer_key, COUNT(*) FROM gold.dim_customers
                GROUP BY customer_key HAVING COUNT(*) > 1
            """,
            "dim_products: duplicate product_key": """
                SELECT product_key, COUNT(*) FROM gold.dim_products
                GROUP BY product_key HAVING COUNT(*) > 1
            """,
            "fact_sales: orphaned customer/product key": """
                SELECT f.* FROM gold.fact_sales f
                LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
                LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
                WHERE p.product_key IS NULL OR c.customer_key IS NULL
            """,
        }
        failures = []
        for name, sql in checks.items():
            rows = hook.get_records(sql)
            if rows:
                failures.append(f"- {name}: {len(rows)} bad row(s)")
        if failures:
            raise ValueError("Gold quality checks failed:\n" + "\n".join(failures))

    load_bronze() >> load_silver() >> quality_check_silver() >> quality_check_gold()

bronze_silver_pipeline()