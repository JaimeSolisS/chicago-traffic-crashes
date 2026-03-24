{{
  config(
    materialized='incremental',
    unique_key='crash_record_id',
    incremental_strategy='merge', 
    partition_by={
      "field": "crash_date",
      "data_type": "date",
      "granularity": "day"
    }
  )
}}
WITH final AS (
    SELECT
        c.crash_record_id,
        -- TIME
        c.crash_date as crash_date,
        c.crash_timestamp as crash_timestamp,
        c.crash_hour,
        c.crash_day_of_week,
        c.crash_month,
        c.crash_year,
        -- ENVIRONMENT / ROAD
        c.weather_condition,
        c.lighting_condition,
        c.roadway_surface_condition,
        c.trafficway_type,
        c.posted_speed_limit,
        -- DETAILS
        c.prim_contributory_cause,
        c.num_units,
        -- INJURIES
        c.injuries_total,
        c.injuries_fatal,
        c.injuries_incapacitating,
        CASE
            WHEN c.injuries_fatal > 0 THEN 'FATAL'
            WHEN c.injuries_incapacitating > 0 THEN 'SERIOUS'
            ELSE 'NON-SERIOUS'
        END AS severity_level,
        CASE
            WHEN c.injuries_fatal > 0 or c.injuries_incapacitating > 0 THEN 1 else 0
        END AS severe_crash_flag,
        -- SPEED
        CASE
            WHEN c.posted_speed_limit IS NULL THEN 'UNKNOWN'
            WHEN c.posted_speed_limit <= 20 THEN '0-20'
            WHEN c.posted_speed_limit BETWEEN 21 AND 30 THEN '21-30'
            WHEN c.posted_speed_limit BETWEEN 31 AND 40 THEN '31-40'
            WHEN c.posted_speed_limit BETWEEN 41 AND 50 THEN '41-50'
            ELSE '51+'
        END AS speed_limit_bucket,
        -- AGGS
        coalesce(p.people_count, 0) as people_count,
        coalesce(p.has_driver, 0) as has_driver,
        coalesce(p.has_known_driver_action, 0) as has_known_driver_action,
        coalesce(p.driver_impairment_flag, 0) as driver_impairment_flag,
        coalesce(p.driver_bac_tested_flag, 0) as driver_bac_tested_flag,
        coalesce(p.severe_injured_people_count, 0) as severe_injured_people_count,
        coalesce(v.vehicle_count, 0) as vehicle_count,
        coalesce(v.vehicle_defect_flag, 0) as vehicle_defect_flag,
        coalesce(v.has_known_vehicle_type, 0) as has_known_vehicle_type,
        coalesce(v.has_known_maneuver, 0) as has_known_maneuver

    FROM {{ ref('int_crashes') }} c
    LEFT JOIN {{ ref('int_people_agg') }} p on c.crash_record_id = p.crash_record_id
    LEFT JOIN {{ ref('int_vehicle_agg') }} v on c.crash_record_id = v.crash_record_id
    {% if is_incremental() %}
    WHERE c.crash_date > (SELECT MAX(crash_date) FROM {{ this }})
    {% endif %}
)

SELECT * FROM final