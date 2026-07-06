# Project Summary

## Overview

A Medallion Architecture (Bronze → Silver → Gold) data warehouse, originally built on SQL Server + Airflow, migrated to a cloud-native stack: **Databricks** (Unity Catalog, Delta Lake, Serverless compute) for transformation and governance, and **AWS S3** as the raw data lake, with the full pipeline orchestrated by a **Databricks Job**.

**One-liner:** Migrated an existing SQL Server + Airflow data warehouse to Databricks + AWS — re-platforming stored-procedure ETL into Spark SQL, connecting Unity Catalog to S3 via IAM, and replacing Airflow with native Databricks Workflows.

---

## Tech Stack

- **Databricks** — Unity Catalog (`datawarehouse` catalog with `bronze`/`silver`/`gold` schemas), Delta Lake managed tables, Serverless SQL Warehouse compute
- **Databricks Jobs (Workflows)** — task orchestration, scheduling, dependency chaining, and failure notifications
- **AWS S3** — raw CRM/ERP CSV landing zone
- **AWS IAM** — Storage Credential (IAM role) provisioned via CloudFormation Quickstart, granting Unity Catalog read access to the S3 bucket through a Unity Catalog External Location
- **Spark SQL** — all bronze/silver/gold transform logic, ported from the original T-SQL stored procedures
- **Git/GitHub** — version control

---

## Architecture

1. **Bronze** — `read_files()` ingests raw CRM/ERP CSVs directly from S3 into managed Delta tables, full-refresh (`CREATE OR REPLACE TABLE`), same intent as the original `BULK INSERT` truncate-and-reload.
2. **Silver** — cleansing/standardization (deduplication, trimming, type/format fixes, invalid-date handling) via CTAS (`CREATE OR REPLACE TABLE ... AS SELECT`) from Bronze.
3. **Gold** — star-schema views (dimension + fact tables) for analytics, unchanged in shape from the original design.
4. **Quality gates** — Spark SQL `assert_true(condition, message)` statements enforce the same checks as the original (null/duplicate keys, invalid date ordering, referential integrity); a failed assertion fails the task.
5. **Orchestration** — one Databricks Job (`medallion_pipeline`) runs `load_bronze → load_silver → quality_check_silver → gold_views → quality_check_gold` on a schedule, each task gated on the previous one succeeding, on Serverless compute, with email alerts on failure.

---

## Troubleshooting / Problem-Solving Highlights — Databricks + AWS Migration

**1. Prior-practice workspace cleanup before building for real**
- The Databricks catalog had leftover tutorial tables (`dirty_data_s3`, `users_dirty_csv`) and several Delta Live Tables pipeline drafts from earlier learning.
- Key lesson: dropping a table isn't sufficient for pipeline-managed objects (streaming tables / materialized views) — the backing pipeline will recreate them on its next run unless the pipeline itself is deleted.
- Also hit Unity Catalog metadata eventual-consistency: a `DROP SCHEMA` briefly reported a stale non-zero table count immediately after the underlying objects had actually already been removed; resolved by waiting and retrying rather than assuming something was wrong.

**2. Connecting Unity Catalog to a real S3 bucket**
- Needed a Unity Catalog External Location backed by a Storage Credential (AWS IAM role) to let Databricks read from the project's own S3 bucket, rather than relying on Databricks' invisible default managed storage.
- Used AWS's CloudFormation Quickstart flow (auto-generates the IAM role/trust policy) instead of hand-authoring an IAM policy.
- First attempt failed with `createStorageCredentials` in a `CREATE_FAILED` state; succeeded on a careful re-run with the correct Databricks account ID and personal access token.

**3. SQL Warehouse compute can't execute Python**
- Initial quality-check implementation ported the original Airflow task's PySpark logic directly, which failed immediately: *"Unsupported cell during execution. SQL warehouses only support executing SQL cells."*
- Rather than switching the notebook to cluster-based compute (more moving parts, more cost), rewrote the checks using Spark SQL's built-in `assert_true(condition, message)` function — kept the entire pipeline on lightweight Serverless SQL Warehouse compute.

**4. Porting T-SQL to Spark SQL**
- Mostly a direct logic port, with a handful of syntax gaps: `ISNULL` → `COALESCE`, `LEN` → `LENGTH`, `GETDATE()` → `CURRENT_DATE()`.
- The sales date columns (`sls_order_dt`, `sls_ship_dt`, `sls_due_dt`), stored as `yyyymmdd` integers, needed `TO_DATE(CAST(col AS STRING), 'yyyyMMdd')` — a plain string→date cast in Spark only parses `yyyy-MM-dd`, unlike T-SQL's more permissive implicit conversion.

**5. Making Bronze reproducible, not a one-off manual upload**
- The first Bronze load was done through Databricks' "Add Data" UI wizard — a one-time table creation, not something that could be re-triggered by a schedule.
- Rebuilt Bronze as a `read_files()`-based SQL notebook so the entire medallion pipeline, not just Silver/Gold, reruns automatically end-to-end inside the Databricks Job — mirroring the original Airflow DAG's daily full pipeline run.
