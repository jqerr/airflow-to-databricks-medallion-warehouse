# SQL Data Warehouse on Databricks + AWS

A Medallion Architecture (Bronze, Silver, Gold) data warehouse built on **Databricks (Delta Lake, Unity Catalog)**, with raw data landing in **AWS S3** and the full pipeline orchestrated by a **Databricks Job**.

**One-liner:** Migrated an existing SQL Server + Airflow data warehouse to a cloud-native Databricks + AWS stack — re-platforming stored-procedure ETL logic into Spark SQL, wiring up Unity Catalog's connection to S3 via IAM, and replacing Airflow with a native Databricks Job.

---

## Architecture

1. **Raw landing zone (AWS S3)**: source CRM/ERP CSVs live in an S3 bucket (`raw/crm/`, `raw/erp/`), connected to Databricks via a Unity Catalog **External Location** backed by an IAM role (Storage Credential).
2. **Bronze Layer**: `read_files()` reads the raw CSVs directly from S3 into managed Delta tables — a full-refresh load, same pattern as the original `BULK INSERT`.
3. **Silver Layer**: Cleansed, standardized, and deduplicated data, transformed from Bronze via `CREATE OR REPLACE TABLE ... AS SELECT` (CTAS) in Spark SQL.
4. **Gold Layer**: Business-ready star schema (dimension and fact views) built on top of Silver.
5. **Quality gates**: Spark SQL's `assert_true()` enforces the same null/duplicate/referential-integrity checks as the original project — a failing assertion fails the task.
6. **Orchestration**: A Databricks Job (`medallion_pipeline`) chains 5 notebook tasks — `load_bronze → load_silver → quality_check_silver → gold_views → quality_check_gold` — each only running if its dependency succeeded, on Serverless compute, with a schedule and failure-email notification.

---

## Tech Stack

- **Databricks** — Unity Catalog (catalog/schema governance), Delta Lake (managed tables), Serverless SQL compute
- **Databricks Jobs (Workflows)** — task orchestration and scheduling, replacing Airflow/Docker
- **AWS S3** — raw data lake storage for source CSVs
- **AWS IAM** — Storage Credential role (via CloudFormation Quickstart) granting Unity Catalog read access to S3
- **Spark SQL** — bronze/silver/gold transform logic, ported from the original T-SQL stored procedures
- **SQL Server / SSMS** — the warehouse's original engine, kept as the project's starting point (see `scripts/`)

---

## Problem-Solving Highlights (Databricks + AWS Migration)

**Cleaning up a messy prior-practice workspace before building for real**
Before starting, the Databricks catalog had leftover tutorial tables and Delta Live Tables pipelines from earlier practice (`dirty_data_s3`, `users_dirty_csv`, several unnamed pipeline drafts). Learned that dropping a table isn't enough for pipeline-managed (streaming table / materialized view) objects — the backing pipeline recreates them unless the pipeline itself is deleted too. Also hit Unity Catalog metadata eventual-consistency: a `DROP SCHEMA` briefly reported stale table counts right after the underlying objects were actually gone.

**Wiring Unity Catalog to a real S3 bucket**
Set up a Unity Catalog External Location backed by a Storage Credential (IAM role), created via AWS's CloudFormation Quickstart flow rather than hand-writing the IAM trust policy — a first attempt failed at `createStorageCredentials` and needed a re-run with correct account/token inputs before the S3 bucket showed up as browsable inside Databricks.

**SQL Warehouse compute can't run Python**
Initially wrote the quality-check logic as PySpark (mirroring the original Airflow task functions), which failed with "SQL warehouses only support executing SQL cells." Rather than switching the notebook to cluster compute, re-implemented the checks using Spark SQL's built-in `assert_true(condition, message)` — keeping the entire pipeline on lightweight Serverless SQL compute with no Python dependency.

**Porting T-SQL to Spark SQL**
Straightforward logic port, but a few syntax gaps needed fixing: `ISNULL` → `COALESCE`, `LEN` → `LENGTH`, `GETDATE()` → `CURRENT_DATE()`, and the original `sls_order_dt`/`sls_ship_dt`/`sls_due_dt` columns (stored as `yyyymmdd` integers) needed `TO_DATE(..., 'yyyyMMdd')` instead of a plain cast, since Spark's string→date cast only accepts `yyyy-MM-dd`.

**Making Bronze reproducible, not a one-off upload**
The first Bronze load was done via Databricks' "Add Data" UI (a one-time manual ingestion). For the pipeline to actually be schedulable end-to-end like the original Airflow DAG, Bronze was rebuilt as a proper `read_files()`-based notebook so every layer — not just Silver/Gold — reruns automatically as part of the Databricks Job.

---

## Repository Structure

```
AIRFLOW/
│
├── dags/                       # Original Airflow DAG (bronze_silver_pipeline.py) — SQL Server version
│
├── datasets/                   # Raw source CSV files (CRM and ERP), also uploaded to S3 for the Databricks version
│
├── docs/                       # Architecture diagrams and data documentation
│   ├── data_catalog.md
│   ├── naming_conventions.md
│   └── project_summary.md
│
├── scripts/                    # Original SQL Server DDL + stored procedures (bronze/silver/gold)
│
├── tests/                      # Original data quality check scripts (SQL Server version)
│
├── config/, docker-compose.yaml  # Original Airflow/Docker setup
├── LICENSE
└── README.md
```

Note: the Databricks notebooks (`load_bronze`, `load_silver`, `quality_check_silver`, `gold_views`, `quality_check_gold`) live in the Databricks workspace, chained together by the `medallion_pipeline` Job — they are the current, active version of this project's ETL logic. The `scripts/`/`dags/` folders reflect the original SQL Server + Airflow implementation this project evolved from.

---

## License

This project is licensed under the [MIT License](LICENSE).
