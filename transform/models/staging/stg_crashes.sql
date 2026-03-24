SELECT 
    -- IDENTITY --
    crash_record_id as crash_record_id,
    -- TIME --
    crash_date as crash_date,
    crash_timestamp as crash_timestamp,
    crash_hour as crash_hour,
    CASE 
        WHEN crash_day_of_week = 1 THEN 'SUNDAY'
        WHEN crash_day_of_week = 2 THEN 'MONDAY'
        WHEN crash_day_of_week = 3 THEN 'TUESDAY'
        WHEN crash_day_of_week = 4 THEN 'WEDNESDAY'
        WHEN crash_day_of_week = 5 THEN 'THURSDAY'
        WHEN crash_day_of_week = 6 THEN 'FRIDAY'
        WHEN crash_day_of_week = 7 THEN 'SATURDAY'
        ELSE 'UNKNOWN'
    END AS crash_day_of_week,
    CASE
        WHEN crash_month = 1 THEN 'JANUARY'
        WHEN crash_month = 2 THEN 'FEBRUARY'
        WHEN crash_month = 3 THEN 'MARCH'
        WHEN crash_month = 4 THEN 'APRIL'
        WHEN crash_month = 5 THEN 'MAY'
        WHEN crash_month = 6 THEN 'JUNE'
        WHEN crash_month = 7 THEN 'JULY'
        WHEN crash_month = 8 THEN 'AUGUST'
        WHEN crash_month = 9 THEN 'SEPTEMBER'
        WHEN crash_month = 10 THEN 'OCTOBER'
        WHEN crash_month = 11 THEN 'NOVEMBER'
        WHEN crash_month = 12 THEN 'DECEMBER'
        ELSE 'UNKNOWN'
    END AS crash_month,
    EXTRACT(YEAR FROM crash_date) as crash_year,
    -- LOCATION --
    street_number as street_number,
    CASE 
        WHEN street_direction = 'N' THEN 'NORTH'
        WHEN street_direction = 'S' THEN 'SOUTH'
        WHEN street_direction = 'E' THEN 'EAST'
        WHEN street_direction = 'W' THEN 'WEST'
        WHEN street_direction = 'NE' THEN 'NORTHEAST'
        WHEN street_direction = 'NW' THEN 'NORTHWEST'
        WHEN street_direction = 'SE' THEN 'SOUTHEAST'
        WHEN street_direction = 'SW' THEN 'SOUTHWEST'
        ELSE 'UNKNOWN'
    END AS street_direction,
    street_name as street_name,
    beat_of_occurrence as beat_of_occurrence,
    latitude as latitude,
    longitude as longitude,
    ST_GEOGPOINT(longitude, latitude) as geo_point,
    -- ROAD CONDITIONS --
    posted_speed_limit as posted_speed_limit,
    trafficway_type as trafficway_type,
    alignment as alignment,
    roadway_surface_condition as roadway_surface_condition,
    road_defect as road_defect,
    traffic_control_device as traffic_control_device,
    device_condition as device_condition,
    -- ENVIRONMENT --
    weather_condition as weather_condition,
    lighting_condition as lighting_condition,
    -- CRASH DETAILS --
    COALESCE(report_type, 'UNKNOWN') as report_type,
    crash_type as crash_type,
    first_crash_type as first_crash_type,
    CASE
        WHEN hit_and_run_i = 'Y' THEN 'YES'
        WHEN hit_and_run_i = 'N' THEN 'NO'
        ELSE 'UNKNOWN'
     END as hit_and_run_i,
    COALESCE(damage, 'UNKNOWN') as damage,
    prim_contributory_cause as prim_contributory_cause,
    sec_contributory_cause as sec_contributory_cause,
    num_units as num_units,
    -- INJURIES --        
    COALESCE(most_severe_injury, 'UNKNOWN') as most_severe_injury,
    COALESCE(injuries_total, 0) as injuries_total,
    COALESCE(injuries_fatal, 0) as injuries_fatal,
    COALESCE(injuries_incapacitating, 0) as injuries_incapacitating,
    COALESCE(injuries_non_incapacitating, 0) as injuries_non_incapacitating,
    COALESCE(injuries_reported_not_evident, 0) as injuries_reported_not_evident,
    COALESCE(injuries_no_indication, 0) as injuries_no_indication,
    COALESCE(injuries_unknown, 0) as injuries_unknown,
    -- ADMINISTRATIVE --
    date_police_notified as date_police_notified
FROM {{ref('raw_crashes')}}
