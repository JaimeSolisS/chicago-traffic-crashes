{{
  config(
    materialized='incremental',
    unique_key='crash_unit_id',
    incremental_strategy='merge', 
    partition_by={
      "field": "crash_date",
      "data_type": "date",
      "granularity": "day"
    }
  )
}}
WITH source AS (
    SELECT
        --Left out columns that are mostly NULL
        -- IDENTITY --
        CAST(crash_unit_id as numeric) as crash_unit_id,
        CAST(unit_no as numeric) as unit_no,
        unit_type as unit_type,
        crash_record_id as crash_record_id,
        crash_date as crash_timestamp,
        DATE(crash_date) as crash_date,
        CAST(vehicle_id as numeric) as vehicle_id,
        -- VEHICLE INFO --
        make as make,
        model as model,
        CAST(vehicle_year as integer) as vehicle_year,
        vehicle_type as vehicle_type,
        vehicle_use as vehicle_use,
        vehicle_defect as vehicle_defect,
        lic_plate_state as lic_plate_state,
        --cmrc_veh_i as cmrc_veh_i,
        -- OCCUPANTS --
        CAST(num_passengers as integer) as num_passengers,
        CAST(occupant_cnt as integer) as occupant_cnt,
        -- MOVEMENT --
        travel_direction as travel_direction,
        maneuver as maneuver,
        -- CRASH INVOLVEMENT --
        first_contact_point as first_contact_point,
        --area_00_i as area_00_i,
        --area_01_i as area_01_i,
        --area_02_i as area_02_i,
        --area_03_i as area_03_i,
        --area_04_i as area_04_i,
        --area_05_i as area_05_i,
        --area_06_i as area_06_i,
        --area_07_i as area_07_i,
        --area_08_i as area_08_i,
        --area_09_i as area_09_i,
        --area_10_i as area_10_i,
        --area_11_i as area_11_i,
        --area_12_i as area_12_i,
        --area_99_i as area_99_i,
        --towed_i as towed_i,
        --towed_by as towed_by,
        --towed_to as towed_to,
        -- Commercial vehicle (mostly NULL)
        --cast(cmv_id as numeric) as cmv_id,
        --usdot_no as usdot_no,
        --ccmc_no as ccmc_no,
        --commercial_src as commercial_src,
        --gvwr as gvwr,
        --vehicle_config as vehicle_config,
        --cargo_body_type as cargo_body_type,
        --load_type as load_type,
        --cast(axle_cnt as integer) as axle_cnt,
        --idot_permit_no as idot_permit_no,
        --trailer1_width as trailer1_width,
        --trailer2_width as trailer2_width,
        --carrier_name as carrier_name,
        --carrier_state as carrier_state,
        --carrier_city as carrier_city,
        --hazmat_present_i as hazmat_present_i,
        --hazmat_report_i as hazmat_report_i,
        --hazmat_report_no as hazmat_report_no,
        --hazmat_vio_cause_crash_i as hazmat_vio_cause_crash_i,
        --hazmat_out_of_service_i as hazmat_out_of_service_i,
        --hazmat_class as hazmat_class,
        --mcs_report_i as mcs_report_i,
        --mcs_vio_cause_crash_i as mcs_vio_cause_crash_i,
        --mcs_out_of_service_i as mcs_out_of_service_i

    FROM {{ source('raw_data', 'external_vehicles') }}

    {% if is_incremental() %}
    WHERE partition_date > (SELECT MAX(crash_date) FROM {{ this }})
    {% endif %}
)

SELECT * FROM source