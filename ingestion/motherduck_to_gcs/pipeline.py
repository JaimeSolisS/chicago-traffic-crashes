import json
import os
import sys
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

CHICAGO_TZ = ZoneInfo("America/Chicago")

from dotenv import load_dotenv

# Load credentials from project root .env before importing dlt
load_dotenv(Path(__file__).parent.parent.parent / ".env")

import dlt
import duckdb
import gcsfs
from dlt.common.configuration.specs import GcpServiceAccountCredentials
from dlt.destinations import filesystem

TABLES = ["crashes", "vehicles", "people"]
MOTHERDUCK_DATASET = os.environ["MOTHERDUCK_DATASET"]
database = os.environ["MOTHERDUCK_DATABASE"]


@dlt.source(name=MOTHERDUCK_DATASET)
def motherduck_source(target_date: date, motherduck_token: str):
    """
    dlt source that reads crash data from MotherDuck for a specific date.

    Yields one resource per table (crashes, vehicles, people), each returning
    an Arrow table so dlt can write it directly as Parquet without row-by-row
    serialization overhead.

    Args:
        target_date: The date to query.
        motherduck_token: MotherDuck authentication token.
    """

    def make_resource(table_name: str):
        @dlt.resource(name=table_name, write_disposition="replace")
        def _resource():
            conn = duckdb.connect(
                f"md:{database}?motherduck_token={motherduck_token}"
            )
            try:
                arrow_table = conn.execute(
                    f"""
                    SELECT *
                    FROM {MOTHERDUCK_DATASET}.{table_name}
                    WHERE crash_date::DATE = ?
                    """,
                    [target_date.isoformat()],
                ).fetch_arrow_table()
                if arrow_table.num_rows > 0:
                    yield arrow_table
            finally:
                conn.close()

        return _resource

    return [make_resource(t) for t in TABLES]


def run(target_date: date | None = None) -> None:
    """
    Export Chicago Traffic Crashes data from MotherDuck to GCS as Parquet.

    Uses dlt's filesystem destination to write one Parquet file per table,
    partitioned by date using Hive-style paths:

        gs://<bucket>/chicago_traffic_crashes/<table>/date=YYYY-MM-DD/<load_id>.parquet

    All credentials are read from the project root .env:
      - MOTHERDUCK_TOKEN
      - BUCKET_NAME
      - CREDENTIALS  (path to GCP service account JSON)

    Args:
        target_date: The date to export. Defaults to yesterday.
    """
    if target_date is None:
        target_date = datetime.now(CHICAGO_TZ).date() - timedelta(days=1)

    date_str = target_date.isoformat()

    motherduck_token = os.environ["MOTHERDUCK_TOKEN"]
    bucket_name = os.environ["BUCKET_NAME"]
    # Pop CREDENTIALS so dlt doesn't intercept it as a GCP OAuth credential config.
    # The value is relative to ingestion/ (e.g. "../keys/gcp_credentials.json").
    credentials_path = os.environ.pop("CREDENTIALS", "")

    # Load the service account JSON and hand it directly to dlt's credential spec
    abs_credentials_path = (Path(__file__).parent.parent / credentials_path).resolve()
    with open(abs_credentials_path) as f:
        sa_info = f.read()
    gcp_credentials = GcpServiceAccountCredentials()
    gcp_credentials.parse_native_representation(sa_info)

    # Delete existing date partitions so re-runs are idempotent (no duplicate files)
    fs = gcsfs.GCSFileSystem(token=json.loads(sa_info))
    for table in TABLES:
        partition = f"{bucket_name}/{MOTHERDUCK_DATASET}/{table}/date={date_str}"
        if fs.exists(partition):
            fs.rm(partition, recursive=True)

    print(f"Exporting data for {date_str} from MotherDuck to GCS ...")

    pipeline = dlt.pipeline(
        pipeline_name="motherduck_to_gcs",
        destination=filesystem(
            bucket_url=f"gs://{bucket_name}",
            credentials=gcp_credentials,
            # Hive-style partitioning: <table>/date=YYYY-MM-DD/<load_id>.parquet
            layout="{table_name}/date={date_partition}/{load_id}.{ext}",
            extra_placeholders={"date_partition": date_str},
        ),
        dataset_name=MOTHERDUCK_DATASET,
    )

    source = motherduck_source(
        target_date=target_date,
        motherduck_token=motherduck_token,
    )

    load_info = pipeline.run(source, loader_file_format="parquet")
    print(load_info)

    # Remove dlt internal tracking folders — keep only data Parquet files
    # Remove all dlt internal tracking folders — keep only data Parquet files
    for path in fs.glob(f"{bucket_name}/{MOTHERDUCK_DATASET}/_dlt_*"):
        fs.rm(path, recursive=True)
    #delete a init file that dlt creates in the root of MOTHERDUCK_DATASET
    init_file = f"{bucket_name}/{MOTHERDUCK_DATASET}/init"
    if fs.exists(init_file):
        fs.rm(init_file)

if __name__ == "__main__":
    # Optionally accept a date argument: python pipeline.py 2026-03-05
    if len(sys.argv) > 1:
        target = date.fromisoformat(sys.argv[1])
    else:
        target = None

    run(target_date=target)
