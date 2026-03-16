# Transform

dbt project for transforming Chicago traffic crash data in BigQuery.

## Setup

### 1. Install dependencies

```bash
pip install dbt-bigquery
```

### 2. Configure the root `.env` file

All GCP credentials and project settings are defined in the `.env` file at the project root. Copy the example and fill in your values:

```bash
cp ../.env.example ../.env
```

Key variables used by this dbt project:

| Variable | Description |
|---|---|
| `CREDENTIALS` | Path to the GCP service account JSON key (e.g. `../keys/gcp_credentials.json`) |
| `PROJECT_ID` | Your GCP project ID |
| `DATASET_ID` | BigQuery dataset where models will be written |
| `LOCATION` | BigQuery dataset location (e.g. `US`) |

Make sure the service account has the `BigQuery Data Editor` and `BigQuery Job User` IAM roles.

### 3. Configure the dbt profile

dbt profiles live in `~/.dbt/profiles.yml`. Add the following entry, substituting the values from your `.env`:

```yaml
chicago_traffic_crashes:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: YOUR_PROJECT_ID        # PROJECT_ID from .env
      dataset: YOUR_DATASET_ID        # DATASET_ID from .env
      location: US                    # LOCATION from .env
      keyfile: /path/to/gcp_credentials.json  # CREDENTIALS from .env
      threads: 4
```

### 4. Initialize the dbt project (first time only)

From the `transform/` directory:

```bash
dbt init
```

Select `bigquery` as the database and follow the wizard. This generates `dbt_project.yml` and the base project structure.

### 5. Verify the connection

```bash
dbt debug
```

All checks should pass. If BigQuery connection fails, double-check the keyfile path and that the service account has the required IAM roles.

### 6. Run models

```bash
# Run all models
dbt run

# Run a specific model
dbt run --select model_name

# Run tests
dbt test
```

## Project structure

```
transform/
├── dbt_project.yml       # Project configuration
├── models/               # SQL transformation models
│   ├── staging/          # Raw source models
│   └── marts/            # Business-level models
├── tests/                # Custom data tests
├── macros/               # Reusable SQL macros
└── seeds/                # Static CSV data
```

## Notes

- Never commit the `.env` file or the service account JSON key to version control — both are in `.gitignore`.
- Use a `dbt-bigquery` version compatible with your dbt Core version (see the [dbt compatibility matrix](https://docs.getdbt.com/docs/core-versions)).
