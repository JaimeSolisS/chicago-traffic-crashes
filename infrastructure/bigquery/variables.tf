variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the BigQuery dataset"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}
