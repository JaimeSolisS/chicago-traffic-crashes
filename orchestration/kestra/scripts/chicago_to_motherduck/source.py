from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

CHICAGO_TZ = ZoneInfo("America/Chicago")

import dlt

from dlt.sources.rest_api import RESTAPIConfig, rest_api_source

BASE_URL = "https://data.cityofchicago.org/resource/"

ENDPOINTS = {
    "crashes": ("85ca-t3if.json", "crash_record_id"),
    "vehicles": ("68nd-jvt3.json", "crash_unit_id"),
    "people": ("u6pd-qa9d.json", "person_id"),
}


def chicago_traffic_crashes_source(target_date: date | None = None) -> dlt.sources.DltSource:
    """
    dlt REST API source for Chicago Traffic Crashes.

    Fetches crashes, vehicles, and people records for the given date
    (defaults to yesterday). Uses offset-based pagination with 1,000
    records per page as required by the SODA 2.0 API.

    Args:
        target_date: The date to fetch data for the previous day. Defaults to yesterday.

    Returns:
        A dlt source with three resources: crashes, vehicles, people.
    """
    if target_date is None:
        target_date = datetime.now(CHICAGO_TZ).date() - timedelta(days=1)

    # SODA stores crash_date in UTC. Convert Chicago midnight → UTC so the filter
    # correctly brackets the full Chicago calendar day regardless of DST.
    next_date = target_date + timedelta(days=1)
    start_utc = datetime(target_date.year, target_date.month, target_date.day,
                         tzinfo=CHICAGO_TZ).astimezone(timezone.utc)
    end_utc = datetime(next_date.year, next_date.month, next_date.day,
                       tzinfo=CHICAGO_TZ).astimezone(timezone.utc)
    where_clause = (
        f"crash_date >= '{start_utc.strftime('%Y-%m-%dT%H:%M:%S.000')}'"
        f" AND crash_date < '{end_utc.strftime('%Y-%m-%dT%H:%M:%S.000')}'"
    )

    config: RESTAPIConfig = {
        "client": {
            "base_url": BASE_URL,
            # Offset paginator: adds $offset and $limit to each request,
            # stops when an empty page (0 records) is returned.
            "paginator": {
                "type": "offset",
                "limit": 1000,
                "offset_param": "$offset",
                "limit_param": "$limit",
                "total_path": None,
                "stop_after_empty_page": True,
            },
        },
        "resources": [
            {
                "name": name,
                "primary_key": primary_key,
                "write_disposition": "merge",
                "endpoint": {
                    "path": path,
                    "params": {
                        "$where": where_clause,
                    },
                },
            }
            for name, (path, primary_key) in ENDPOINTS.items()
        ],
    }

    return rest_api_source(config)
