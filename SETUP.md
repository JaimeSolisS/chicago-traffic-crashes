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
