import os
import sys
from datetime import date, timedelta
from pathlib import Path

from dotenv import load_dotenv

# Load credentials from project root .env before importing dlt
load_dotenv(Path(__file__).parent.parent.parent / ".env")

import dlt

sys.path.insert(0, str(Path(__file__).parent))
from source import chicago_traffic_crashes_source


def run(target_date: date | None = None) -> None:
    """
    Load Chicago Traffic Crashes data into MotherDuck.

    Fetches crashes, vehicles, and people records for the given date
    (defaults to yesterday) and writes them into separate tables inside
    the `chicago_traffic_crashes` dataset in MotherDuck.

    Args:
        target_date: The date to fetch. Defaults to yesterday.
    """
    if target_date is None:
        target_date = date.today() - timedelta(days=1)

    token = os.environ["MOTHERDUCK_TOKEN"]
    database = os.environ["MOTHERDUCK_DATABASE"]
    # Pop CREDENTIALS so dlt doesn't intercept it as a GCP OAuth credential config
    os.environ.pop("CREDENTIALS", None)
    # Expose as dlt env var so the motherduck destination picks it up
    os.environ["DESTINATION__MOTHERDUCK__CREDENTIALS"] = (
        f"md:{database}?motherduck_token={token}"
    )

    print(f"Loading data for {target_date.isoformat()} into MotherDuck ...")

    pipeline = dlt.pipeline(
        pipeline_name="chicago_traffic_crashes",
        destination="motherduck",
        dataset_name="main",
    )

    source = chicago_traffic_crashes_source(target_date=target_date)

    load_info = pipeline.run(source)
    print(load_info)


if __name__ == "__main__":
    # Optionally accept a date argument: python pipeline.py 2026-03-05
    if len(sys.argv) > 1:
        target = date.fromisoformat(sys.argv[1])
    else:
        target = None

    run(target_date=target)
