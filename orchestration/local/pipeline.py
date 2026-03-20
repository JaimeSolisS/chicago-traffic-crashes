import subprocess
from datetime import datetime, timedelta

start_date = datetime(2025, 9, 2)
end_date = datetime(2025, 9, 3)

current = start_date

while current <= end_date:
    date_str = current.strftime("%Y-%m-%d")
    print(f"--- Running pipelines for {date_str} ---")

    print(f"--- CHICAGO TO MOTHERDUCK ---")
    subprocess.run(
        ["uv", "run", "chicago_to_motherduck/pipeline.py", date_str],
        check=True,
        cwd="../../ingestion"
    )

    print(f"--- MOTHERDUCK TO GCS ---")
    subprocess.run(
        ["uv", "run", "motherduck_to_gcs/pipeline.py", date_str],
        check=True,
        cwd="../../ingestion"
    )

    # This can be run outside the loop, so dbt only runs once, 
    # but this is how the pipeline should work on a daily basis.
    print("--- RUN DBT ---")
    subprocess.run(
        ["make", "dbt-run"],
        check=True,
        cwd="../.."
    )

    current += timedelta(days=1)



print("All dates completed.")