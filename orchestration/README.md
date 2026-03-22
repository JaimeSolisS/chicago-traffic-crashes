# Orchestration

Two ways to run the pipeline: a local Python script for development and backfills, and a Kestra workflow for scheduled production runs.

```
orchestration/
├── local/
│   └── pipeline.py          # Date-range loop: runs all three stages via subprocess
└── kestra/
    ├── docker-compose.yml   # Kestra + Postgres
    ├── flows/
    │   └── chicago_traffic_crashes_pipeline.yaml
    └── scripts/
        ├── chicago_to_motherduck/
        │   └── pipeline.py  # Namespace file: Chicago API → MotherDuck
        └── motherduck_to_gcs/
            └── pipeline.py  # Namespace file: MotherDuck → GCS Parquet
```

---

## Local

`orchestration/local/pipeline.py` iterates over a date range and runs the full pipeline for each day by invoking the ingestion scripts and dbt via `subprocess`.

To run a backfill, edit the `start_date` and `end_date` at the top of the file:

```python
start_date = datetime(2025, 9, 2)
end_date   = datetime(2025, 9, 3)
```

Then from the project root:

```bash
make local-pipeline
```

Each iteration runs in order:
1. `chicago_to_motherduck/pipeline.py <date>` — fetch from Chicago Data Portal → MotherDuck
2. `motherduck_to_gcs/pipeline.py <date>` — export MotherDuck → GCS Parquet
3. `make dbt-run` — run dbt transformations in BigQuery

Credentials and config are read from the root `.env`.

---

## Kestra

Scheduled workflow that runs the same three stages daily. All secrets come from the Kestra KV Store — no `.env` file is needed.

### Flow: `chicago_traffic_crashes_flow`

**Trigger:** daily at 12:00 UTC (`0 12 * * *`), passing `trigger.date - 1 day` as the target date.

**Tasks (in order):**

| Task | Type | What it does |
| ---- | ---- | ------------ |
| `build_image` | `docker.Build` | Builds a Python image with dlt, `duckdb==1.4.4`, and all deps |
| `api_to_motherduck` | `python.Commands` | Runs `chicago_to_motherduck/pipeline.py` from namespace files |
| `motherduck_to_gcs` | `python.Commands` | Runs `motherduck_to_gcs/pipeline.py` from namespace files |
| `dbt_bigquery` | `WorkingDirectory` | Clones the repo from GitHub, then runs `dbt run` via the dbt-bigquery container |

### Scripts (namespace files)

The scripts under `kestra/scripts/` are synced to Kestra as namespace files for the `chicago_traffic_crashes` namespace. They are identical in logic to `ingestion/` but read all config from environment variables injected by the flow (no `load_dotenv`).

- `chicago_to_motherduck/pipeline.py` — reads `MOTHERDUCK_TOKEN`, `MOTHERDUCK_DATABASE`, `MOTHERDUCK_DATASET`
- `motherduck_to_gcs/pipeline.py` — reads the above plus `BUCKET_NAME` and `GCP_CREDENTIALS_JSON` (full service account JSON string)

### dbt task

The `dbt_bigquery` task clones the repository at runtime so it always uses the latest version of the transform models. The dbt profile is defined inline in the flow YAML — no `~/.dbt/profiles.yml` required. GCP credentials are passed via `inputFiles` as `gcp_keyfile.json`.

`sources.yml` uses `env_var('PROJECT_ID')` and `env_var('DATASET_ID')`, which are injected via the task's `env:` block from KV store values.

### Docker Compose

Kestra runs with a Postgres backend. `/var/run/docker.sock` is mounted so Kestra can spin up Docker containers for tasks.

```bash
make kestra-up    # start
make kestra-down  # stop
```

### KV Store keys

All secrets are stored in **Namespaces → chicago_traffic_crashes → KV Store**:

| Key | Type |
| --- | ---- |
| `MOTHERDUCK_TOKEN` | STRING |
| `MOTHERDUCK_DATABASE` | STRING |
| `MOTHERDUCK_DATASET` | STRING |
| `BUCKET_NAME` | STRING |
| `GCP_PROJECT_ID` | STRING |
| `GCP_BIGQUERY_DATASET` | STRING |
| `GCP_CREDENTIALS_JSON` | JSON |
| `GITHUB_USERNAME` | STRING |
| `GITHUB_REPO` | STRING |
