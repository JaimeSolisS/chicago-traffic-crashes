variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the bucket"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket for raw data"
  type        = string
}

variable "storage_class" {
  description = "Storage class for the GCS bucket"
  type        = string
  default = "STANDARD"
}
