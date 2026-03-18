SELECT 
    -- IDENTITY --
    crash_unit_id as crash_unit_id,
    unit_no as unit_no,
    COALESCE(unit_type, 'UNKNOWN') as unit_type,
    crash_record_id as crash_record_id,
    crash_date as crash_date,
    vehicle_id as vehicle_id,
    -- VEHICLE INFO --
    COALESCE(make, 'UNKNOWN') as make,
    COALESCE(model, 'UNKNOWN') as model,
    vehicle_year as vehicle_year,
    COALESCE(vehicle_type, 'UNKNOWN/NA') as vehicle_type,
    COALESCE(vehicle_use, 'UNKNOWN/NA') as vehicle_use,
    COALESCE(vehicle_defect, 'UNKNOWN') as vehicle_defect,
    COALESCE(lic_plate_state, 'UNKNOWN') as lic_plate_state,
    -- OCCUPANTS --
    num_passengers as num_passengers,
    occupant_cnt as occupant_cnt,
    -- MOVEMENT --
    CASE 
        WHEN travel_direction = 'N' THEN 'NORTH'
        WHEN travel_direction = 'S' THEN 'SOUTH'
        WHEN travel_direction = 'E' THEN 'EAST'
        WHEN travel_direction = 'W' THEN 'WEST'
        WHEN travel_direction = 'NE' THEN 'NORTHEAST'
        WHEN travel_direction = 'NW' THEN 'NORTHWEST'
        WHEN travel_direction = 'SE' THEN 'SOUTHEAST'
        WHEN travel_direction = 'SW' THEN 'SOUTHWEST'
        ELSE 'UNKNOWN'
    END AS travel_direction,
    COALESCE(maneuver, 'UNKNOWN/NA') as maneuver,
    -- CRASH INVOLVEMENT --
    COALESCE(first_contact_point, 'UNKNOWN') as first_contact_point
FROM {{ref('raw_vehicle')}}