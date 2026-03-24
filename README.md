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
- **Staging Layer:** MotherDuck (DuckDB cloud) for intermediate storage and deduplication.
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

- **Git** for cloning the repository
- **Google Cloud Platform (GCP):** A project with billing enabled and APIs for GCS and BigQuery activated
- **Terraform** for provisioning infrastructure
- **Docker** for running Kestra locally
- **uv** (Python package manager) for running ingestion pipelines
- **dbt** for running transformations
- **GCP Credentials:** A service account key (JSON) with access to GCS and BigQuery
- **MotherDuck account** with a personal access token

### Tools

| Tool      | Version | Install                                                                                        |
| --------- | ------- | ---------------------------------------------------------------------------------------------- |
| Terraform | ≥ 1.0   | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
| Docker    | latest  | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/)                              |
| Python    | ≥ 3.13  | [python.org/downloads](https://www.python.org/downloads/)                                      |
| uv        | latest  | `curl -LsSf https://astral.sh/uv/install.sh \| sh`                                             |

### Accounts & services

- **GCP project** with billing enabled ([console.cloud.google.com](https://console.cloud.google.com/))
    - A service account with the following roles:
        - `roles/storage.admin`
        - `roles/bigquery.dataOwner`
    - A JSON key file downloaded for that service account

- **MotherDuck** — sign up at [motherduck.com](https://motherduck.com)
    - Generate a Personal Access Token (Settings → Access Tokens)
    - Create a database (Attached Databases → +)

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

## Step 1 — Clone the repository

```bash
git clone <repo-url>
cd chicago-traffic-crashes
```

## Step 2 — Add your GCP service account key

Place the downloaded JSON key file at:

```
keys/gcp_credentials.json
```

## Step 3 — Configure environment variables

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

## Step 4 — Provision GCP infrastructure

Uses Terraform to create the GCS bucket and BigQuery dataset. From the project root:

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

This provisions:

- **GCS bucket** — stores raw Parquet files
- **BigQuery dataset** — for downstream analysis

## Step 5 — Install ingestion dependencies

```bash
make dlt-sync
```

## Step 5.1 (optional) - Add the dlt MCP Server Config

```bash
claude mcp add dlt -- uv run --with "dlt[motherduck,gs]" --with "dlt-mcp[search]" python -m dlt_mcp
```

## Step 6 — Run the ingestion pipelines

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

### Stage 2 — MotherDuck → GCS

```bash
uv run motherduck_to_gcs/pipeline.py
```

To export a specific date:

```bash
uv run motherduck_to_gcs/pipeline.py 2026-03-05
```

## Step 7 - Create External Tables in BigQuery

In BigQuery run, if you use other dataset names update as required

```sql
CREATE OR REPLACE EXTERNAL TABLE `chicago_traffic_crashes.external_crashes`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://de-zoomcamp-484622-chicago-traffic-crashes/raw/crashes/*'],
  hive_partition_uri_prefix = 'gs://de-zoomcamp-484622-chicago-traffic-crashes/raw/crashes/'
);

CREATE OR REPLACE EXTERNAL TABLE `chicago_traffic_crashes.external_people`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://de-zoomcamp-484622-chicago-traffic-crashes/raw/people/*'],
  hive_partition_uri_prefix = 'gs://de-zoomcamp-484622-chicago-traffic-crashes/raw/people/'
);


CREATE OR REPLACE EXTERNAL TABLE `chicago_traffic_crashes.external_vehicles`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://de-zoomcamp-484622-chicago-traffic-crashes/raw/vehicles/*'],
  hive_partition_uri_prefix = 'gs://de-zoomcamp-484622-chicago-traffic-crashes/raw/vehicles/'
);

```

## Step 8 — Set up dbt (transform)

### Install dbt

```bash
pip install dbt-bigquery
```

### Configure the dbt profile

Add the following to `~/.dbt/profiles.yml`, substituting values from your `.env`:

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
            keyfile: /path/to/gcp_credentials.json # CREDENTIALS from .env
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

## Step 9 — Set up Kestra

> **Running locally without Kestra:** The pipeline can also be run directly from the command line. Edit the date range in `orchestration/local/pipeline.py`, then:
>
> ```bash
> make local-pipeline
> ```

From the project root, start Kestra and its backing Postgres database:

```bash
make kestra-up
```

Kestra will be available at [localhost:8080](http://localhost:8080).

### Sync flows and scripts from GitHub

Before syncing, make sure you have pushed the repository to GitHub — Kestra pulls the flows and scripts directly from your remote branch. Or you can copy and paste in Kestra the flow and the scripts manually.

Inside Kestra, create and execute the following flow once to pull the pipeline flow and scripts from your repository. After the initial run it can be triggered manually whenever you push changes.

Go to **Flows → + Create** and paste:

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

For more information see [kestra.io/docs/how-to-guides/syncflows](https://kestra.io/docs/how-to-guides/syncflows).

### Configure the KV Store

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

### Run the pipeline

Go to **Flows → chicago_traffic_crashes → chicago_traffic_crashes_flow** and use **Backfill executions** to load historical dates.

**Step 10 Visualize in Looker Studio**

Connect Looker Studio to the dataset in BigQuery and you can create your own the dashboard.

Step 11 Clean up resources

```bash
make terraform-destroy
```
