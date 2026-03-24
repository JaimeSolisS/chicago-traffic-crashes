# Chicago Traffic Crashes

End-to-end data engineering project analyzing traffic crash data from the City of Chicago.

## Problem

Chicago reports over 100,000 traffic crashes each year, but only a portion of them result in the most serious outcomes—fatal or incapacitating injuries that have significant human and economic impact. This project focuses on identifying when and under what conditions these severe crashes are most likely to occur.

The Chicago Traffic Crash dataset was selected because it provides separate but related data on crashes, people, and vehicles, allowing analysis across multiple perspectives (environment, driver, and vehicle). It is also continuously updated, making it suitable for building a pipeline that can handle daily refreshed data.

To support this analysis, a batch data pipeline was built to ingest, store, and transform the data on a daily schedule. Raw records flow from the Chicago Data Portal into MotherDuck, then into Google Cloud Storage as Parquet files, and finally into BigQuery where dbt models clean and aggregate them into an analytics-ready mart visualized in a Looker Studio dashboard. The pipeline is orchestrated with Kestra and Google Cloud infrastructure is provisioned with Terraform. While the MotherDuck staging step is not strictly necessary, it was intentionally included to practice working with multiple tools across different stages of a pipeline.

## Infrastructure

|                                                                                                  Cloud & IaC                                                                                                   |                                                                                   Orchestration                                                                                    |                                                                                                                                                          Storage                                                                                                                                                          |                                                                                                       Ingestion & Transformation                                                                                                        |                                                Visualization                                                |
| :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------: |
| [![Terraform](https://img.shields.io/badge/Terraform-844FBA?logo=terraform&logoColor=white)](#) <br> [![Google Cloud](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=googlecloud&logoColor=white)](#) | [![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](#) <br> [![Kestra](https://img.shields.io/badge/Kestra-7C3AED?logo=kestra&logoColor=white)](#) | [![MotherDuck](https://img.shields.io/badge/MotherDuck-FCD34D?logo=duckdb&logoColor=black)](#) <br> ![Cloud Storage](https://img.shields.io/badge/Cloud%20Storage-4285F4?logo=googlecloudstorage&logoColor=white) <br> [![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?logo=googlebigquery&logoColor=white)](#) | [![dlt](https://img.shields.io/badge/dlt-47C8FF?logo=data&logoColor=1a1f3a)](#)[![Hub](https://img.shields.io/badge/Hub-C8FF00?logoColor=1a1f3a)](#) <br> [![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)](#) | [![Looker Studio](https://img.shields.io/badge/Looker%20Studio-4285F4?logo=googlecloud&logoColor=white)](#) |

## Setup

**1. Clone the repo**

```bash
git clone <repo-url>
cd chicago-traffic-crashes
```

**2. Provision infrastructure**

See [infrastructure/README.md](infrastructure/README.md) for full setup instructions.

See [SETUP.md](SETUP.md) (Step 8) for dbt installation, profile configuration, and connection verification.
