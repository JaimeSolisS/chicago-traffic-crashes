# Infrastructure

Terraform configuration to provision GCP resources for the Chicago Traffic Crashes project.

## Resources

- **GCS Bucket** — stores raw data files
- **BigQuery Dataset** — `chicago_traffic_crashes` for analysis

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

## Setup

For prerequisites and environment variable setup, see [README.md](../README.md#4--provision-gcp-infrastructure) (Step 4).
