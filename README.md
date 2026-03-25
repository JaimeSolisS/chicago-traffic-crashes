# Chicago Traffic Crashes

End-to-end data engineering project analyzing traffic crash data from the City of Chicago.

## Table of Contents

- [Overview](#overview)
- [Technologies Used](#technologies-used)
- [Architecture](#architecture)
- [Dashboard](#dashboard)
- [Setup and Installation](#setup-and-installation)
- [Challenges and Learnings](#challenges-and-learnings)
- [Future Improvements](#future-improvements)

## Overview

This project, developed as the final submission for the **DE Zoomcamp 2026 cohort**, builds an end-to-end batch data pipeline to process and analyze traffic crash data from the City of Chicago. The pipeline ingests raw crash records daily from the Chicago Data Portal, stages them in MotherDuck, stores them in a data lake on Google Cloud Storage as partitioned Parquet files, transforms them in BigQuery using dbt, and visualizes key insights through a Looker Studio dashboard. The pipeline is orchestrated with Kestra and Google Cloud infrastructure is provisioned with Terraform.

A daily batch pipeline ingests crash data from the Chicago Data Portal into MotherDuck, exports it to Google Cloud Storage as Parquet files, loads it into BigQuery, and applies dbt transformations to produce an analytics-ready mart visualized in Looker Studio. The MotherDuck staging step was intentionally included to practice working with multiple tools across different stages of a pipeline.

## Problem Statement

**Problem:** Chicago reports over 100,000 traffic crashes each year, but only a portion result in fatal or incapacitating injuries that carry significant human and economic impact. Without an automated pipeline, it is difficult to continuously process the three related datasets (crashes, people, vehicles), deduplicate records, and surface actionable patterns in crash severity.

## Infrastructure

|                                                                                                  Cloud & IaC                                                                                                   |                                                                                   Orchestration                                                                                    |                                                                                                                                                          Storage                                                                                                                                                          |                                                                                                       Ingestion & Transformation                                                                                                        |                                                Visualization                                                |
| :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------: |
| [![Terraform](https://img.shields.io/badge/Terraform-844FBA?logo=terraform&logoColor=white)](#) <br> [![Google Cloud](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=googlecloud&logoColor=white)](#) | [![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](#) <br> [![Kestra](https://img.shields.io/badge/Kestra-7C3AED?logo=kestra&logoColor=white)](#) | [![MotherDuck](https://img.shields.io/badge/MotherDuck-FCD34D?logo=duckdb&logoColor=black)](#) <br> ![Cloud Storage](https://img.shields.io/badge/Cloud%20Storage-4285F4?logo=googlecloudstorage&logoColor=white) <br> [![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?logo=googlebigquery&logoColor=white)](#) | [![dlt](https://img.shields.io/badge/dlt-47C8FF?logo=data&logoColor=1a1f3a)](#)[![Hub](https://img.shields.io/badge/Hub-C8FF00?logoColor=1a1f3a)](#) <br> [![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)](#) | [![Looker Studio](https://img.shields.io/badge/Looker%20Studio-4285F4?logo=googlecloud&logoColor=white)](#) |

### Technologies Used

- **Cloud:** Google Cloud Platform (GCP) for storage and data warehousing.
- **Infrastructure as Code (IaC):** Terraform to provision GCS buckets and BigQuery datasets.
- **Workflow Orchestration:** Kestra (via Docker) for daily batch scheduling.
- **Staging Warehouse:** MotherDuck (DuckDB cloud) for intermediate storage and deduplication.
- **Data Lake:** Google Cloud Storage (GCS) — Hive-partitioned Parquet files.
- **Data Warehouse:** Google BigQuery, with partitioned tables.
- **Ingestion:** dlt (data load tool) with `rest_api_source` for the Chicago SODA 2.0 API and DuckDB connector for MotherDuck → GCS.
- **Transformations:** dbt for data modeling, cleaning, and aggregation in BigQuery.
- **Visualization:** Looker Studio for the dashboard.

## Architecture

The pipeline follows a daily batch processing workflow:

1. **Ingestion (dltHub):**
    - **Chicago API → MotherDuck:** dlt hits the Chicago SODA 2.0 API with offset-based pagination (1,000 rows/page), filtering by date (Chicago timezone → UTC). Records are deduplicated via merge disposition on primary keys (`crash_record_id`, `crash_unit_id`, `person_id`) and loaded into MotherDuck across three tables: `crashes`, `vehicles`, and `people`.
    - **MotherDuck → GCS:** A second dlt pipeline queries MotherDuck via DuckDB, fetches Arrow tables partitioned by `crash_date`, and writes Hive-partitioned Parquet files to GCS (`gs://BUCKET/DATASET/crashes/date=YYYY-MM-DD/`). Existing partitions are deleted before writing, making the step idempotent.

    See [Ingestion](infrastructure/README.md) for more details.

2. **Loading (GCS → BigQuery):** Raw Parquet files are loaded from GCS into BigQuery staging tables with partitioning for query optimization.
3. **Transformation (dbt):** dbt models clean, join, and aggregate the three datasets into a production mart in BigQuery, computing crash severity flags, time-of-day features, and location aggregations.

    See [Transform](transform/README.md) for more details.

4. **Visualization (Looker Studio):** The mart is connected to a Looker Studio dashboard surfacing crash severity trends and contributing factors.
5. **Orchestration (Kestra):** Kestra, running via Docker, schedules and orchestrates all pipeline stages daily.
   See [Orchestration](orchestration/README.md) for more details.
6. **Infrastructure (Terraform):** The GCS bucket and BigQuery datasets are provisioned with Terraform for reproducibility.
   See [Infrastructure](infrastructure/README.md) for more details.

### Architecture Diagram

![Chicago Traffic Crashes Data Pipeline Architecture](img/ArchitectureDiagram.png)

## Crash Severity Risk Dashboard

This dashboard analyzes when severe traffic crashes are most likely to occur and the key factors associated with more serious outcomes.

A severe crash is defined as any crash that results in:

at least one fatal injury, or
at least one incapacitating injury (serious injuries that prevent normal activity, such as broken bones)

The dashboard combines data from crashes, people, and vehicles to provide a more complete view of:

time patterns (when crashes happen)
contributing causes (what led to the crash)
environmental conditions (weather and road surface)
risk factors (driver condition vs vehicle issues)

## Setup and Installation

## Prerequisites

Make sure you have the following installed and configured before starting.

### Tools

| Tool      | Version | Purpose                      |
| --------- | ------- | ---------------------------- |
| Git       | latest  | Clone the repository         |
| Terraform | >= 1.0  | Provision GCP infrastructure |
| Docker    | latest  | Run Kestra locally           |
| Python    | >= 3.11 | Run ingestion pipelines      |
| uv        | latest  | Python package manager       |
| dbt       | latest  | Run transformations          |

Install links:

- Terraform: https://developer.hashicorp.com/terraform/install
- Docker: https://docs.docker.com/get-docker/
- Python: https://www.python.org/downloads/
- uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`

---

## Required Accounts and Services

### Google Cloud Platform (GCP)

You need:

- A **GCP project** with billing enabled: ([console.cloud.google.com](https://console.cloud.google.com/))
- The following APIs enabled:
    - **Cloud Storage API**
    - **BigQuery API**
- A **service account** with at least:
    - `roles/storage.admin`
    - `roles/bigquery.dataOwner`
- A downloaded **JSON key file** for that service account

### MotherDuck

You need:

- A MotherDuck account: https://motherduck.com
- A **Personal Access Token**
- A database created in MotherDuck

### Optional: GitHub

GitHub is required only if you want Kestra to sync flows and scripts directly from your repository.

---

### Repository Structure

```
chicago-traffic-crashes/
├── ingestion/
│   ├── chicago_to_motherduck/
│   │   ├── source.py          # dlt rest_api_source for Chicago SODA API
│   │   └── pipeline.py        # Stage 1: Chicago API → MotherDuck
│   ├── motherduck_to_gcs/
│   │   └── pipeline.py        # Stage 2: MotherDuck → GCS Parquet
│   └── pyproject.toml
├── infrastructure/
│   ├── gcs/                   # Terraform module: GCS bucket
│   ├── bigquery/              # Terraform module: BigQuery dataset
│   └── README.md
├── transform/                 # dbt project targeting BigQuery
│   └── README.md
├── keys/
│   └── gcp_credentials.json   # GCP service account key (not committed)
├── .env                       # Environment variables (copy from .env.example)
├── .env.example
├── Makefile
└── README.md
```

## 1 — Clone the repository

```bash
git clone <repo-url>
cd chicago-traffic-crashes
```

## 2 — Add your GCP service account key

Place the downloaded JSON key file at:

```
keys/gcp_credentials.json
```

## 3 — Configure environment variables

Copy the example file and fill in your values:

```bash
cp .env.example .env
```

| Variable              | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| `CREDENTIALS`         | Path to service account JSON (relative to `ingestion/`)          |
| `PROJECT_ID`          | GCP project ID                                                   |
| `REGION`              | GCP region (e.g. `us-central1`)                                  |
| `LOCATION`            | GCP location for BigQuery (e.g. `US`)                            |
| `BUCKET_NAME`         | GCS bucket name for raw Parquet files                            |
| `DATASET_ID`          | BigQuery dataset ID (e.g. `chicago_traffic_crashes`)             |
| `MOTHERDUCK_TOKEN`    | MotherDuck Personal Access Token                                 |
| `MOTHERDUCK_DATABASE` | MotherDuck database name (e.g. `chicago_crashes`)                |
| `MOTHERDUCK_DATASET`  | Schema inside the database, also used as GCS prefix (e.g. `raw`) |
| `KESTRA_USERNAME`     |                                                                  |
| `KESTRA_PASSWORD`     |                                                                  |

> [!NOTE]
> Since the ingestion commands are run from inside ingestion/, the CREDENTIALS path should usually be ../keys/gcp_credentials.json.

## 4 — Provision GCP infrastructure

Uses Terraform to create the GCS bucket and BigQuery dataset.

```bash
make terraform-init
make terraform-apply
```

Or run Terraform directly from `infrastructure/`:

```bash
cd infrastructure
terraform init
terraform apply -var="project_id=..." -var="bucket_name=..." ...
```

This creates:

- A **GCS bucket** for raw Parquet files
- A **BigQuery dataset** for downstream analytics
  Expected result

After this step, you should be able to confirm:

The bucket exists in GCS
The dataset exists in BigQuery

## 5 — Install ingestion dependencies

```bash
make dlt-sync
```

## 6 (optional) - Add the dlt MCP Server Config

```bash
claude mcp add dlt -- uv run --with "dlt[motherduck,gs]" --with "dlt-mcp[search]" python -m dlt_mcp
```

Skip this step if you do not need MCP integration.

## 7 — Run the ingestion pipelines

Both pipelines default to **yesterday's date** when run with no arguments.

### Stage 1 — Chicago API → MotherDuck

```bash
cd ingestion
uv run chicago_to_motherduck/pipeline.py
```

To load a specific date:

```bash
uv run chicago_to_motherduck/pipeline.py 2026-03-05
```

Expected result
The selected day’s data should be loaded into MotherDuck.

### Stage 2 — MotherDuck → GCS

```bash
uv run motherduck_to_gcs/pipeline.py
```

To export a specific date:

```bash
uv run motherduck_to_gcs/pipeline.py 2026-03-05
```

Expected result
Parquet files should appear in your GCS bucket under the expected prefixes, for example:

```
gs://<BUCKET_NAME>/raw/crashes/
gs://<BUCKET_NAME>/raw/people/
gs://<BUCKET_NAME>/raw/vehicles/
```

## 8 - Create External Tables in BigQuery

Run the following in the BigQuery SQL Editor, replacing:

- `YOUR_DATASET_ID`
- `YOUR_BUCKET_NAME`

with your own values.

```sql
CREATE OR REPLACE EXTERNAL TABLE `YOUR_DATASET_ID.external_crashes`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://YOUR_BUCKET_NAME/raw/crashes/*'],
  hive_partition_uri_prefix = 'gs://YOUR_BUCKET_NAME/raw/crashes/'
);

CREATE OR REPLACE EXTERNAL TABLE `YOUR_DATASET_ID.external_people`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://YOUR_BUCKET_NAME/raw/people/*'],
  hive_partition_uri_prefix = 'gs://YOUR_BUCKET_NAME/raw/people/'
);

CREATE OR REPLACE EXTERNAL TABLE `YOUR_DATASET_ID.external_vehicles`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://YOUR_BUCKET_NAME/raw/vehicles/*'],
  hive_partition_uri_prefix = 'gs://YOUR_BUCKET_NAME/raw/vehicles/'
);
```

Expected result

You should be able to query:

- `external_crashes`
- `external_people`
- `external_vehicles`

from your BigQuery dataset.

## 9. Set up dbt

### Install dbt

```bash
pip install dbt-bigquery
```

### Configure the dbt profile

Add this to ~/.dbt/profiles.yml, replacing placeholders with your values:

```yaml
chicago_traffic_crashes:
    target: dev
    outputs:
        dev:
            type: bigquery
            method: service-account
            project: YOUR_PROJECT_ID # PROJECT_ID from .env
            dataset: YOUR_DATASET_ID # DATASET_ID from .env
            location: us-central1 # REGION from .env
            keyfile: /absolute/path/to/gcp_credentials.json
            threads: 1
```

### Verify the connection

```bash
make dbt-debug
```

All checks should pass. If BigQuery connection fails, double-check the keyfile path and that the service account has the required IAM roles.

### Run models

```bash
make dbt-run
```

Expected result

dbt should complete successfully and create transformed models in BigQuery.

## Running without Kestra

You can run the pipeline locally without orchestration.

Edit the date range in:

```
orchestration/local/pipeline.py
```

Then run:

```bash
make local-pipeline
```

## Runing with Kestra

# 10. Start Kestra locally

From the project root

```bash
make kestra-up
```

Kestra will be available at [localhost:8080](http://localhost:8080).

### 11. Sync flows and scripts from GitHub

If you want Kestra to pull flows and scripts from GitHub, first push your repository to GitHub.

In Kestra, go to:

Flows → + Create

Then paste and run:

```yaml
id: sync_flows_from_git
namespace: system

tasks:
    - id: sync_flows
      type: io.kestra.plugin.git.SyncFlows
      url: https://github.com/{YOUR_GITHUB_USERNAME}/{YOUR_GITHUB_REPO}
      branch: main
      targetNamespace: chicago_traffic_crashes
      gitDirectory: orchestration/kestra/flows
      dryRun: false

    - id: sync_files
      type: io.kestra.plugin.git.SyncNamespaceFiles
      url: https://github.com/{YOUR_GITHUB_USERNAME}/{YOUR_GITHUB_REPO}
      branch: main
      namespace: chicago_traffic_crashes
      gitDirectory: orchestration/kestra/scripts
      dryRun: false
```

For more details see [kestra.io/docs/how-to-guides/syncflows](https://kestra.io/docs/how-to-guides/syncflows).

> [!Note]
> If you do not want to use GitHub sync, you can copy and paste the flows and scripts into Kestra manually.

### 12. Configure the KV Store

Go to **Namespaces → chicago_traffic_crashes → KV Store** and add the following key-value pairs:

| Key                    | Type   | Description                             |
| ---------------------- | ------ | --------------------------------------- |
| `BUCKET_NAME`          | STRING | GCS bucket name                         |
| `GCP_BIGQUERY_DATASET` | STRING | BigQuery dataset ID                     |
| `GCP_CREDENTIALS_JSON` | JSON   | Contents of `keys/gcp_credentials.json` |
| `GCP_PROJECT_ID`       | STRING | GCP project ID                          |
| `GITHUB_REPO`          | STRING | GitHub repository name                  |
| `GITHUB_USERNAME`      | STRING | GitHub username                         |
| `MOTHERDUCK_DATABASE`  | STRING | MotherDuck database name                |
| `MOTHERDUCK_DATASET`   | STRING | MotherDuck schema (e.g. `raw`)          |
| `MOTHERDUCK_TOKEN`     | STRING | MotherDuck Personal Access Token        |

> [!Danger]
> Treat these values as sensitive credentials and store them carefully.

### 13. Run the pipeline in Kestra

Go to:

**Flows → chicago_traffic_crashes → chicago_traffic_crashes_flow**

Use Backfill executions to load historical dates.

Expected result

Kestra should execute the ingestion and orchestration flow successfully for the selected time range.

### Visualization

### 14 Build dashboards in Looker Studio

Connect Looker Studio to your BigQuery dataset and build dashboards using the transformed dbt models.

Recommended approach:

Use the dbt models instead of the raw external tables when possible
Start with metrics such as:
crashes by date
crashes by location
contributing causes
vehicle counts
people involved by injury severity

### 15 Cleanup

When you are done, remove the provisioned resources:

```bash
make terraform-destroy
```
