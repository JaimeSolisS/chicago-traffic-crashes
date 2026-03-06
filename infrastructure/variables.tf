variable "credentials" {
  description = "Path to the GCP service account credentials JSON file"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
}

variable "location" {
  description = "Project Location"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket for raw data"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}
