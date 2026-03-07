from datetime import date, timedelta

import dlt
from dlt.sources.rest_api import RESTAPIConfig, rest_api_source

BASE_URL = "https://data.cityofchicago.org/resource/"

ENDPOINTS = {
    "crashes": "85ca-t3if.json",
    "vehicles": "68nd-jvt3.json",
    "people": "u6pd-qa9d.json",
}


def chicago_traffic_crashes_source(target_date: date | None = None) -> dlt.sources.DltSource:
    """
    dlt REST API source for Chicago Traffic Crashes.

    Fetches crashes, vehicles, and people records for the given date
    (defaults to yesterday). Uses offset-based pagination with 1,000
    records per page as required by the SODA 2.0 API.

    Args:
        target_date: The date to fetch data for. Defaults to yesterday.

    Returns:
        A dlt source with three resources: crashes, vehicles, people.
    """
    if target_date is None:
        target_date = date.today() - timedelta(days=1)

    start_dt = f"{target_date.isoformat()}T00:00:00.000"
    end_dt = f"{(target_date + timedelta(days=1)).isoformat()}T00:00:00.000"
    where_clause = f"crash_date >= '{start_dt}' AND crash_date < '{end_dt}'"

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
                "endpoint": {
                    "path": path,
                    "params": {
                        "$where": where_clause,
                    },
                },
            }
            for name, path in ENDPOINTS.items()
        ],
    }

    return rest_api_source(config)
