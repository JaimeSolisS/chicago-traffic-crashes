SELECT 
    -- IDENTITY --
    person_id as person_id,
    person_type as person_type,
    crash_record_id as crash_record_id,
    vehicle_id as vehicle_id,
    crash_date as crash_date,
    crash_timestamp as crash_timestamp,
    -- DEMOGRAPHICS --
    COALESCE(sex, 'UNKNOWN') as sex,
    age as age,
    COALESCE(city, 'UNKNOWN') as city, 
    COALESCE(state, 'UNKNOWN') as state,
    zipcode as zipcode,
    -- DRIVER INFO --
    COALESCE(drivers_license_state, 'UNKNOWN') as drivers_license_state,
    COALESCE(drivers_license_class, 'UNKNOWN')  as drivers_license_class,
    COALESCE(driver_action, 'UNKNOWN') as driver_action,
    COALESCE(driver_vision, 'UNKNOWN')  as driver_vision,
    COALESCE(physical_condition, 'UNKNOWN')  as physical_condition,
    -- SAFETY & INJURY --
    COALESCE(safety_equipment, 'USAGE UNKNOWN') as safety_equipment,
    COALESCE(airbag_deployed, 'DEPLOYMENT UNKNOWN') as airbag_deployed,
    COALESCE(ejection, 'UNKNOWN') as ejection,
    COALESCE(injury_classification, 'UNKNOWN') as injury_classification,
    COALESCE(bac_result, 'UNKNOWN') as bac_result
FROM {{ref('raw_people')}}