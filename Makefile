include .env
export

TF_DIR = infrastructure
DLT_DIR = ingestion
DBT_DIR = transform
LOCAL_PIPE_DIR = orchestration/local
KESTRA_DIR = orchestration/kestra

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

dlt-sync: 
	cd ${DLT_DIR} && \
	uv sync

dbt-debug:
	cd ${DBT_DIR} && \
	dbt debug

dbt-run:
	cd ${DBT_DIR} && \
	dbt run

dbt-seed:
	cd ${DBT_DIR} && \
	dbt seed

local-pipeline:
	cd ${LOCAL_PIPE_DIR} && \
	python pipeline.py

kestra-up:
	cd ${KESTRA_DIR} && \
	docker-compose up -d

kestra-down:
	cd $(KESTRA_DIR) && 
	docker-compose down