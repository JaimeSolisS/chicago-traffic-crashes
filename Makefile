include .env
export

TF_DIR = infrastructure

TF_VARS = \
	-var="credentials=$(CREDENTIALS)" \
	-var="project_id=$(PROJECT_ID)" \
	-var="region=$(REGION)" \
	-var="location=$(LOCATION)" \
	-var="bucket_name=$(BUCKET_NAME)" \
	-var="dataset_id=$(DATASET_ID)"

terraform-init:
	cd $(TF_DIR) && \
	terraform init

terraform-apply:
	cd $(TF_DIR) && \
	terraform validate && \
	terraform apply $(TF_VARS)

terraform-destroy:
	cd $(TF_DIR) && \
	terraform destroy