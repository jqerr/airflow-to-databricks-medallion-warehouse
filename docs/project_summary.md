# Project Summary

## Overview

A SQL Server data warehouse built on the **Medallion Architecture** (Bronze → Silver → Gold), with the entire pipeline automated and orchestrated by **Apache Airflow** running in **Docker**. It ingests raw CRM and ERP data from CSV files, cleans and standardizes it, models it into a star schema for reporting, and runs unattended on a daily schedule with automated data-quality gating.

**One-liner:** Took an existing SQL Server data warehouse project and built a full orchestration layer around it with Airflow and Docker — including debugging real infrastructure issues and adding automated data quality checks that gate the pipeline.

---

## Tech Stack

- **SQL Server** — warehouse engine; stored procedures for load logic, views for the gold/reporting layer
- **SSMS** — manual DB administration, permissions, debugging
- **Apache Airflow** — scheduling, task dependencies, monitoring, retries
- **Docker / Docker Compose** — runs Airflow's full service stack (webserver, scheduler, worker, triggerer, Postgres metadata DB, Redis) in isolated containers
- **Python** — Airflow DAG definitions (TaskFlow API), using `MsSqlHook` to talk to SQL Server
- **Git/GitHub** — version control

---

## Architecture

1. **Bronze** — raw ingestion via `BULK INSERT` from CRM/ERP CSVs, truncate-and-reload pattern.
2. **Silver** — cleansing/standardization (deduplication, trimming, type/format fixes, invalid-date handling) from Bronze.
3. **Gold** — star-schema views (dimension + fact tables) for analytics, always live since they're views over Silver.
4. **Orchestration** — one Airflow DAG runs `load_bronze → load_silver → quality_check_silver → quality_check_gold` daily at 2am, with each step only proceeding if the previous one succeeds.

---

## Troubleshooting / Problem-Solving Highlights

**1. Docker container couldn't reach SQL Server ("Connection refused")**
- Symptom: Airflow's task failed immediately with a networking error when trying to connect to SQL Server.
- Diagnosis: distinguished "connection refused" (reached the host, nothing listening on the port) from a timeout (never reached it at all) — pointed to SQL Server not actually listening on a fixed TCP port.
- Root cause: SQL Server Express was running as a named instance (`SQLEXPRESS`) using a dynamic port, and Windows Authentication only — neither works from inside a Docker container.
- Fix: enabled SQL Server Authentication (Mixed Mode), created a dedicated `airflow_user` SQL login, enabled TCP/IP with a static port (1433) in SQL Server Configuration Manager, opened that port in Windows Firewall, and verified with `netstat` that SQL Server was actually listening before retesting.

**2. BULK INSERT permission error**
- After fixing connectivity, `EXEC bronze.load_bronze` failed with a permissions error specific to `BULK INSERT`.
- Diagnosis: realized `db_owner` (database-level) doesn't cover `BULK INSERT`, which requires a **server-level** permission.
- Fix: granted `ADMINISTER BULK OPERATIONS` to the Airflow SQL login at the server level.

**3. Hardcoded, environment-specific file paths**
- The bronze load procedure had `BULK INSERT ... FROM 'C:\...'` paths pointing to a folder structure from a different machine/setup than the current project location.
- Fix: identified the mismatch by reading the actual error output, located the real dataset paths, and updated the stored procedure to match — a good example of environment-specific config not surviving a project move/rename.

**4. Turning informal data-quality scripts into automated gates**
- The project had "quality check" SQL scripts meant to be run manually and eyeballed (comment: *"Expectation: No Results"*) — not something a computer could act on.
- Converted the genuine pass/fail checks (null/duplicate keys, invalid date ordering, referential integrity between fact/dimension tables, etc.) into real Airflow tasks that fail the pipeline run if bad rows are found, while leaving purely exploratory checks (like "list distinct values for eyeballing") out of automation since they have no fixed right answer.
- Hit a **false positive** almost immediately: a birthdate range check flagged 15 rows as invalid, using a cutoff of 1924. Investigated the actual flagged data, determined these were legitimate customers born in the early 1900s (not corrupted data — the original threshold was just an arbitrary guess), and adjusted the business rule to a more realistic cutoff rather than either ignoring the failure or wrongly "fixing" data that wasn't actually broken.
