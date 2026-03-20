# Chicago Traffic Crashes

End-to-end data engineering project analyzing traffic crash data from the City of Chicago.

## Problem

Chicago averages over 100,000 traffic crashes per year, yet not all crashes are equal — a small subset result in fatal or incapacitating injuries that carry devastating human and economic costs. This project builds an end-to-end data pipeline ingesting crash, vehicle, and people records from the Chicago Data Portal into a cloud analytics stack (MotherDuck → Google Cloud Storage → BigQuery → dbt), culminating in a data mart designed to answer one central question: when, where, and under what conditions are severe crashes most likely to occur? By integrating environmental factors (weather, lighting, road surface), driver behavior (impairment, known actions), and vehicle characteristics, the analysis surfaces the patterns that matter most — enabling city planners, traffic engineers, and public safety officials to move from reactive reporting to targeted, evidence-based intervention.

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
