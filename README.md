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

# BLA Bla

Based on your staging models, here are the columns for each mart:

mart_crashes_summary — one row per crash (main fact table)

crash_record_id, crash_date, crash_year*, crash_hour, crash_day_of_week, crash_month,
street_number, street_direction, street_name, beat_of_occurrence, latitude, longitude,
weather_condition, lighting_condition, posted_speed_limit,
roadway_surface_condition, road_defect, traffic_control_device,
crash_type, first_crash_type, hit_and_run_i, damage,
prim_contributory_cause, sec_contributory_cause,
most_severe_injury, injuries_total, injuries_fatal, injuries_incapacitating,
injuries_non_incapacitating, injuries_reported_not_evident, injuries_unknown,
num_units, total_people_involved*, total_vehicles_involved\*

- derived/joined

mart_crashes_by_time — aggregated

crash_year, crash_month, crash_day_of_week, crash_hour,
total_crashes, total_injuries, total_fatalities, pct_fatal
mart_crashes_by_location — aggregated by beat

beat_of_occurrence,
total_crashes, total_injuries, total_fatalities,
avg_injuries_per_crash
mart_crashes_by_cause — aggregated

prim_contributory_cause, sec_contributory_cause,
total_crashes, total_injuries, total_fatalities, pct_fatal
mart_crashes_by_condition — aggregated

weather_condition, lighting_condition, roadway_surface_condition,
total_crashes, total_injuries, total_fatalities
mart_people_involved — one row per person joined to crash

person_id, person_type, crash_record_id, crash_date, crash_year\*,
sex, age, state,
drivers_license_state, driver_action, driver_vision, physical_condition,
safety_equipment, airbag_deployed, ejection,
injury_classification, bac_result,
-- from crash join:
latitude, longitude, beat_of_occurrence, prim_contributory_cause, most_severe_injury
