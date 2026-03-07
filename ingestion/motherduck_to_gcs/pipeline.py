import os
import sys
from datetime import date, timedelta
from pathlib import Path

from dotenv import load_dotenv

# Load credentials from project root .env before importing dlt
load_dotenv(Path(__file__).parent.parent.parent / ".env")

import dlt
import duckdb
from dlt.common.configuration.specs import GcpServiceAccountCredentials
from dlt.destinations import filesystem

TABLES = ["crashes", "vehicles", "people"]
MOTHERDUCK_SCHEMA = "main"
database = os.environ["MOTHERDUCK_DATABASE"]


@dlt.source(name="main")
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
                    FROM {MOTHERDUCK_SCHEMA}.{table_name}
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
        target_date = date.today() - timedelta(days=1)

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
        dataset_name="main",
    )

    source = motherduck_source(
        target_date=target_date,
        motherduck_token=motherduck_token,
    )

    load_info = pipeline.run(source, loader_file_format="parquet")
    print(load_info)


if __name__ == "__main__":
    # Optionally accept a date argument: python pipeline.py 2026-03-05
    if len(sys.argv) > 1:
        target = date.fromisoformat(sys.argv[1])
    else:
        target = None

    run(target_date=target)
