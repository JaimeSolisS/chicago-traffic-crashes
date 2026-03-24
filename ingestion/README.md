# Chicago Traffic Crashes — Ingestion

Two-stage daily ingestion pipeline that pulls Chicago traffic crash data from the city's public API, stores it in MotherDuck, and exports it to Google Cloud Storage as date-partitioned Parquet files.

## Architecture

```
Chicago Data Portal (SODA API)
  │  crashes / vehicles / people
  │  offset-paginated JSON (1,000 rows/page)
  │
  ▼
chicago_to_motherduck/pipeline.py   (dlt REST API source)
  │
  ▼
MotherDuck  ──  database: MOTHERDUCK_DATABASE
                schema:   MOTHERDUCK_DATASET
                tables:   crashes | vehicles | people
  │
  ▼
motherduck_to_gcs/pipeline.py   (dlt filesystem destination)
  │
  ▼
Google Cloud Storage
  gs://<BUCKET_NAME>/<MOTHERDUCK_DATASET>/<table>/partition_date=YYYY-MM-DD/<load_id>.parquet
```

## Folder structure

```
ingestion/
├── pyproject.toml
├── uv.lock
├── chicago_to_motherduck/
│   ├── source.py        # dlt REST API source (pagination, date filter)
│   └── pipeline.py      # Chicago API → MotherDuck
└── motherduck_to_gcs/
    └── pipeline.py      # MotherDuck → GCS Parquet
```

> For prerequisites and full setup, see [SETUP.md](../SETUP.md).

## Running the pipelines

Both pipelines default to **yesterday's date** when run with no arguments.

### Step 1 — Chicago API → MotherDuck

```bash
cd ingestion
uv run chicago_to_motherduck/pipeline.py
```

To load a specific date:

```bash
uv run chicago_to_motherduck/pipeline.py 2026-03-05
```

This creates (or merges into) three tables in MotherDuck under the schema set by `MOTHERDUCK_DATASET`:

| Table                           | Source endpoint  |
| ------------------------------- | ---------------- |
| `<MOTHERDUCK_DATASET>.crashes`  | `85ca-t3if.json` |
| `<MOTHERDUCK_DATASET>.vehicles` | `68nd-jvt3.json` |
| `<MOTHERDUCK_DATASET>.people`   | `u6pd-qa9d.json` |

Records are deduplicated on load using primary keys (`crash_record_id`, `crash_unit_id`, `person_id`).

### Step 2 — MotherDuck → GCS

```bash
uv run motherduck_to_gcs/pipeline.py
```

To export a specific date:

```bash
uv run motherduck_to_gcs/pipeline.py 2026-03-05
```

### GCS output layout

Files are written using Hive-style date partitioning under the prefix set by `MOTHERDUCK_DATASET`:

```
gs://<BUCKET_NAME>/<MOTHERDUCK_DATASET>/
├── crashes/
│   └── partition_date=2026-03-05/
│       └── <load_id>.parquet
├── vehicles/
│   └── partition_date=2026-03-05/
│       └── <load_id>.parquet
└── people/
    └── partition_date=2026-03-05/
        └── <load_id>.parquet
```

Re-running the pipeline for the same date overwrites the existing partition (idempotent). dlt internal files are automatically removed after each run.

## Reproducing with the dlt MCP server

The following prompt reproduces this ingestion folder from scratch using the [dlt MCP server](https://github.com/dlt-hub/dlt-mcp):

```
Build a two-stage dlt ingestion pipeline for Chicago Traffic Crashes data.

## Stage 1 — chicago_to_motherduck

Create ingestion/chicago_to_motherduck/source.py and ingestion/chicago_to_motherduck/pipeline.py.

Source:
- Use dlt's rest_api_source with base URL https://data.cityofchicago.org/resource/
- Fetch three endpoints with offset pagination ($offset / $limit, 1000 rows/page, stop on empty page):
    - crashes   → 85ca-t3if.json  (primary key: crash_record_id)
    - vehicles  → 68nd-jvt3.json  (primary key: crash_unit_id)
    - people    → u6pd-qa9d.json  (primary key: person_id)
- write_disposition = "merge" for all three resources
- Filter each endpoint with a $where clause: crash_date >= '<start_utc>' AND crash_date < '<end_utc>'
  where start_utc and end_utc bracket the full Chicago calendar day (America/Chicago timezone)
  converted to UTC and formatted as 'YYYY-MM-DDTHH:MM:SS.000' (no timezone offset in the string,
  because the SODA API does not accept ISO 8601 offset notation).
- The source accepts an optional target_date (date). When None, default to yesterday in Chicago time.

Pipeline:
- Destination: motherduck, dataset_name read from env var MOTHERDUCK_DATASET
- Read MOTHERDUCK_TOKEN and MOTHERDUCK_DATABASE from env; set
  DESTINATION__MOTHERDUCK__CREDENTIALS = "md:{database}?motherduck_token={token}"
- Pop CREDENTIALS from env before importing dlt so dlt does not intercept it as a GCP OAuth config
- Load project root .env with python-dotenv before importing dlt
- Accept an optional CLI date argument (YYYY-MM-DD); default to yesterday

## Stage 2 — motherduck_to_gcs

Create ingestion/motherduck_to_gcs/pipeline.py.

Source:
- dlt source that connects to MotherDuck with duckdb, queries each table
  (crashes, vehicles, people) filtered by crash_date::DATE = <target_date>
  and yields Arrow tables (fetch_arrow_table) for zero-copy Parquet writing.
- Schema name read from env var MOTHERDUCK_DATASET.

Pipeline:
- Destination: dlt filesystem destination pointing at gs://<BUCKET_NAME>
- Layout: {table_name}/date={date_partition}/{load_id}.{ext}
  with extra_placeholder date_partition = target_date ISO string
- dataset_name = MOTHERDUCK_DATASET
- Credentials: load GCP service account JSON from path in env var CREDENTIALS
  (relative to ingestion/), parse with GcpServiceAccountCredentials.parse_native_representation
- Before running: delete existing date partitions in GCS with gcsfs for idempotency
- After running: remove all _dlt_* folders and the init file under the dataset prefix in GCS
- Load project root .env with python-dotenv before importing dlt
- Pop CREDENTIALS from env before importing dlt
- Accept an optional CLI date argument (YYYY-MM-DD); default to yesterday in Chicago time

## Project config

Create ingestion/pyproject.toml with:
- requires-python >= 3.13
- dependencies: dlt[gs,motherduck], python-dotenv, requests

All credentials come from a .env file at the project root (not .dlt/secrets.toml).
```

## Data sources

All data comes from the [Chicago Data Portal](https://data.cityofchicago.org) via the SODA 2.0 API (paginated JSON, 1,000 rows per request).

| Dataset                    | Endpoint                                                 |
| -------------------------- | -------------------------------------------------------- |
| Traffic Crashes — Crashes  | `https://data.cityofchicago.org/resource/85ca-t3if.json` |
| Traffic Crashes — Vehicles | `https://data.cityofchicago.org/resource/68nd-jvt3.json` |
| Traffic Crashes — People   | `https://data.cityofchicago.org/resource/u6pd-qa9d.json` |
