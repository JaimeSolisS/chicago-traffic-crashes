module "gcs" {
  source = "./gcs"

  project_id  = var.project_id
  region      = var.region
  bucket_name = var.bucket_name
}

module "bigquery" {
  source = "./bigquery"

  project_id = var.project_id
  region     = var.region
  dataset_id = var.dataset_id
}
