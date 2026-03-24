SELECT
    -- IDENTITY --
    crash_record_id,
    -- TIME --
    crash_date as crash_date,
    crash_timestamp as crash_timestamp,
    crash_hour,
    crash_day_of_week,
    crash_month,
    crash_year,
    -- ENVIRONMENT --
    weather_condition,
    lighting_condition,
    -- ROAD CONDITIONS --
    roadway_surface_condition,
    trafficway_type,
    posted_speed_limit,
    -- CRASH DETAILS --
    prim_contributory_cause,
    num_units,
    -- INJURIES --     
    injuries_total,
    injuries_fatal,
    injuries_incapacitating

FROM {{ ref('stg_crashes') }}