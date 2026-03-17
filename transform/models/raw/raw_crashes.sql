WITH source AS (
    SELECT
        --Left out columns that are mostly NULL
        -- IDENTITY --
        crash_record_id as crash_record_id,
        -- TIME --
        crash_date as crash_date,
        --crash_date_est_i as crash_date_est_i,
        CAST(crash_hour as integer) as crash_hour,
        CAST(crash_day_of_week as integer) as crash_day_of_week,
        CAST(crash_month as integer) as crash_month,
        -- LOCATION --
        CAST(street_no as numeric) as street_number,
        street_direction as street_direction,
        street_name as street_name,
        CAST(beat_of_occurrence as numeric) as beat_of_occurrence,
        CAST(latitude as numeric) as latitude,
        CAST(longitude as numeric) as longitude,
        --location__type as location_type
        -- ROAD CONDITIONS --
        CAST(posted_speed_limit as numeric) as posted_speed_limit,
        trafficway_type as trafficway_type,
        alignment as alignment,
        roadway_surface_cond as roadway_surface_condition,
        road_defect as road_defect,
        traffic_control_device as traffic_control_device,
        device_condition as device_condition,
        -- ENVIRONMENT --
        weather_condition as weather_condition,
        lighting_condition as lighting_condition,
        -- CRASH DETAILS --
        report_type as report_type,
        crash_type as crash_type,
        first_crash_type as first_crash_type,
        hit_and_run_i as hit_and_run_i,
        damage as damage,
        prim_contributory_cause as prim_contributory_cause,
        sec_contributory_cause as sec_contributory_cause,
        CAST(num_units as integer) as num_units,
        --intersection_related_i as intersection_related_i,
        --private_property_i as private_property_i,
        --dooring_i as dooring_i,
        --work_zone_i as work_zone_i,
        --work_zone_type as work_zone_type,
        -- INJURIES --        
        most_severe_injury as most_severe_injury,
        CAST(injuries_total as integer) as injuries_total,
        CAST(injuries_fatal as integer) as injuries_fatal,
        CAST(injuries_incapacitating as integer) as injuries_incapacitating,
        CAST(injuries_non_incapacitating as integer) as injuries_non_incapacitating,
        CAST(injuries_reported_not_evident as integer) as injuries_reported_not_evident,
        CAST(injuries_no_indication as integer) as injuries_no_indication,
        CAST(injuries_unknown as integer) as injuries_unknown,
        -- ADMINISTRATIVE --
        date_police_notified as date_police_notified
        --photos_taken_i as photos_taken_i,
        --statements_taken_i as statements_taken_i,

    FROM {{ source('raw_data', 'external_crashes') }}
)

SELECT * FROM SOURCE