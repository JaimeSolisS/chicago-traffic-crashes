{{
  config(
    materialized='incremental',
    unique_key='person_id',
    incremental_strategy='merge'
  )
}}

WITH source AS (
    SELECT
        --Left out columns that are mostly NULL
        -- IDENTITY --
        person_id as person_id,
        person_type as person_type,
        crash_record_id as crash_record_id,
        vehicle_id as vehicle_id,
        crash_date as crash_date,
        -- DEMOGRAPHICS --
        sex as sex,
        CAST(age as integer) as age,
        city as city,
        state as state,
        zipcode as zipcode,
        -- DRIVER INFO --
        drivers_license_state as drivers_license_state,
        drivers_license_class as drivers_license_class,
        driver_action as driver_action,
        driver_vision as driver_vision,
        physical_condition as physical_condition,
        -- SAFETY & INJURY --
        --seat_no as seat_no,
        safety_equipment as safety_equipment,
        airbag_deployed as airbag_deployed,
        ejection as ejection,
        injury_classification as injury_classification,
        bac_result as bac_result,
        --hospital as hospital,
        --ems_agency as ems_agency,
        --ems_run_no as ems_run_no,
        -- PEDESTRIAN/CYCLIST --
        --pedpedal_action as pedpedal_action,
        --pedpedal_visibility as pedpedal_visibility,
        --pedpedal_location as pedpedal_location

    FROM {{ source('raw_data', 'external_people') }}
    
    {% if is_incremental() %}
    WHERE crash_date > (SELECT MAX(crash_date) FROM {{ this }})
    {% endif %}
)

SELECT * FROM source