output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = module.gcs.bucket_name
}

output "bucket_url" {
  description = "GCS bucket URL"
  value       = module.gcs.bucket_url
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = module.bigquery.dataset_id
}
