# Infrastructure

Terraform configuration to provision GCP resources for the Chicago Traffic Crashes project.

## Resources

- **GCS Bucket** — stores raw data files
- **BigQuery Dataset** — `chicago_traffic_crashes` for analysis

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- A [GCP project](https://console.cloud.google.com/) with billing enabled
- A GCP service account with the following roles:
    - `roles/storage.admin`
    - `roles/bigquery.dataOwner`
- The service account key downloaded as JSON and placed at `keys/gcp_credentials.json` (relative to the project root)
- `keys/gcp_credentials.json` is gitignored, but you can find an example inside the directory.

## Structure

```
infrastructure/
├── providers.tf       # Google provider configuration
├── variables.tf       # Root-level variables
├── main.tf            # Calls the gcs and bigquery modules
├── outputs.tf         # Exposes bucket and dataset identifiers
├── gcs/
│   ├── main.tf        # google_storage_bucket resource
│   └── variables.tf
└── bigquery/
    ├── main.tf        # google_bigquery_dataset resource
    └── variables.tf
```

## Usage

From the project root, use the provided Makefile targets:

```bash
# Initialize Terraform and download providers
make terraform-init

# Validate and apply the configuration
make terraform-apply

# Destroy all provisioned resources
make terraform-destroy
```

Or run Terraform directly from the `infrastructure/` directory (variables must be passed manually or via a `terraform.tfvars` file):

```bash
cd infrastructure
terraform init
terraform validate
terraform apply -var="project_id=..." -var="bucket_name=..." ...
terraform destroy -var="project_id=..." -var="bucket_name=..." ...
```

## Configuration

All variables are loaded from a `.env` file at the project root. Copy the example and fill in your values:

```bash
cp .env.example .env
```

| Variable      | Description                      |
| ------------- | -------------------------------- |
| `CREDENTIALS` | Path to service account JSON key |
| `PROJECT_ID`  | GCP project ID                   |
| `REGION`      | GCP region                       |
| `LOCATION`    | GCP location (for BigQuery)      |
| `BUCKET_NAME` | GCS bucket name                  |
| `DATASET_ID`  | BigQuery dataset ID              |

> `.env` is gitignored. See `.env.example` for the expected format.
