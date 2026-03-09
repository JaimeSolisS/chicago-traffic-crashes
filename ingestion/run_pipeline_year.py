import subprocess
from datetime import datetime, timedelta

start_date = datetime(2025, 1, 2)
end_date = datetime(2026, 1, 1)

current = start_date

while current <= end_date:
    date_str = current.strftime("%Y-%m-%d")
    print(f"--- Running pipelines for {date_str} ---")

    print(f"--- CHICAGO TO MOTHERDUCK ---")
    subprocess.run(
        ["uv", "run", "chicago_to_motherduck/pipeline.py", date_str],
        check=True
    )

    print(f"--- MOTHERDUCK TO GCS ---")
    subprocess.run(
        ["uv", "run", "motherduck_to_gcs/pipeline.py", date_str],
        check=True
    )

    current += timedelta(days=1)

print("All dates completed.")