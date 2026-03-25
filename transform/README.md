# Transform

dbt project for transforming Chicago traffic crash data in BigQuery. Models clean, enrich, and aggregate raw crash, vehicle, and people records into an analytics-ready mart for severity analysis.

## Model Layers

```
raw/ → staging/ → intermediate/ → marts/
```

### raw/

Materialized as **incremental tables** (merge strategy on unique key). These models pull from the external source tables, cast columns to their correct types, and convert `crash_date` timestamps to date format. Only new rows are processed on each run, filtered by `partition_date`.

Partitioned by `crash_date` (DATE, day granularity).

| Model         | Source table        | Unique key        |
| ------------- | ------------------- | ----------------- |
| `raw_crashes` | `external_crashes`  | `crash_record_id` |
| `raw_vehicle` | `external_vehicles` | `crash_unit_id`   |
| `raw_people`  | `external_people`   | `person_id`       |

> The upstream external tables (`external_crashes`, `external_vehicles`, `external_people`) are partitioned by `partition_date` — a `DATE` column derived from the Hive partition path (`partition_date=YYYY-MM-DD`) written by the ingestion pipeline.

### staging/

Materialized as **views**. Apply business logic on top of raw models: label encoding (day names, month names, street directions), `COALESCE` for nulls, and derived columns like `crash_year` and `geo_point`.

| Model         | Description                                                           |
| ------------- | --------------------------------------------------------------------- |
| `stg_crashes` | Cleans and enriches crash records; adds geo point and readable labels |
| `stg_vehicle` | Cleans vehicle records; selects relevant columns                      |
| `stg_people`  | Cleans people records; selects relevant columns                       |

### intermediate/

Materialized as **views**. Prepare data for the mart layer — one model narrows crash columns to what's needed for severity analysis, the other two aggregate vehicle and people metrics per crash.

| Model             | Description                                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| `int_crashes`     | Selects the crash fields used downstream (time, environment, road, injuries)                       |
| `int_people_agg`  | Per-crash aggregations: people count, driver flags, impairment flag, BAC flag, severe injury count |
| `int_vehicle_agg` | Per-crash aggregations: vehicle count, defect flag, known vehicle type, known maneuver             |

### marts/

Materialized as **incremental tables** (merge strategy on `crash_record_id`). The final analytics layer joins all intermediate models into a single wide table ready for Looker Studio.

Partitioned by `crash_date` (DATE, day granularity).

| Model                 | Description                                                                                                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `mart_crash_severity` | One row per crash with severity classification (`FATAL` / `SERIOUS` / `NON-SERIOUS`), speed bucket, all environment/road conditions, and aggregated people and vehicle metrics |

## Commands

```bash
dbt debug                          # verify BigQuery connection
dbt run                            # run all models
dbt run --select model_name        # run a single model
dbt test                           # run tests
dbt run --full-refresh             # rebuild all incremental models from scratch
```

## Setup

See [README.md](../README.md#9-optional--set-up-dbt) (Step 9) for dbt installation, profile configuration, and connection verification.
