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
  gs://<BUCKET_NAME>/<MOTHERDUCK_DATASET>/<table>/date=YYYY-MM-DD/<load_id>.parquet
```

## Project structure

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

| Table                          | Source endpoint  |
| ------------------------------ | ---------------- |
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
│   └── date=2026-03-05/
│       └── <load_id>.parquet
├── vehicles/
│   └── date=2026-03-05/
│       └── <load_id>.parquet
└── people/
    └── date=2026-03-05/
        └── <load_id>.parquet
```

Re-running the pipeline for the same date overwrites the existing partition (idempotent). dlt internal files are automatically removed after each run.

## Data sources

All data comes from the [Chicago Data Portal](https://data.cityofchicago.org) via the SODA 2.0 API (paginated JSON, 1,000 rows per request).

| Dataset                    | Endpoint                                                 |
| -------------------------- | -------------------------------------------------------- |
| Traffic Crashes — Crashes  | `https://data.cityofchicago.org/resource/85ca-t3if.json` |
| Traffic Crashes — Vehicles | `https://data.cityofchicago.org/resource/68nd-jvt3.json` |
| Traffic Crashes — People   | `https://data.cityofchicago.org/resource/u6pd-qa9d.json` |
