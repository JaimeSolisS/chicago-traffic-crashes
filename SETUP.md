# Setup Guide

End-to-end setup for the Chicago Traffic Crashes project: GCP infrastructure provisioning and daily ingestion pipelines.

## Prerequisites

### Tools

| Tool      | Version | Install                                                                                        |
| --------- | ------- | ---------------------------------------------------------------------------------------------- |
| Terraform | ≥ 1.0   | [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) |
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

Fetches crash, vehicle, and people records from the Chicago Data Portal and writes them into MotherDuck:

| Table                           | Primary key       |
| ------------------------------- | ----------------- |
| `<MOTHERDUCK_DATASET>.crashes`  | `crash_record_id` |
| `<MOTHERDUCK_DATASET>.vehicles` | `crash_unit_id`   |
| `<MOTHERDUCK_DATASET>.people`   | `person_id`       |

Records are deduplicated on load using their primary keys.

### Stage 2 — MotherDuck → GCS

```bash
uv run motherduck_to_gcs/pipeline.py
```

To export a specific date:

```bash
uv run motherduck_to_gcs/pipeline.py 2026-03-05
```

Reads from MotherDuck and writes Hive-partitioned Parquet files to GCS:

```
gs://<BUCKET_NAME>/<MOTHERDUCK_DATASET>/
├── crashes/
│   └── date=2026-03-05/
│       └── <load_id>.parquet
├── vehicles/
│   └── date=2026-03-05/
│       └── <load_id>.parquet
└── people/
    └── date=2026-03-05/
        └── <load_id>.parquet
```

Re-running for the same date overwrites the existing partition (idempotent).

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
