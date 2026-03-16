with source as (
    select
        --Left out columns that are mostly NULL
        person_id as person_id,
        person_type as person_type,
        crash_record_id as crash_record_id,
        vehicle_id  as vehicle_id,
        crash_date as crash_date, 
        --seat_no as seat_no,
        city as city,
        state as state,
        zipcode as zipcode,
        sex as sex, 
        cast(age as integer) as age,
        drivers_license_state as drivers_license_state,
        drivers_license_class as drivers_license_class,
        safety_equipment as safety_equipment,
        airbag_deployed as airbag_deployed,
        ejection as ejection, 
        injury_classification as injury_classification, 
        --hospital as hospital, 
        --ems_agency as ems_agency, 
        --ems_run_no as ems_run_no, 
        driver_action as driver_action,
        driver_vision as driver_vision, 
        physical_condition as physical_condition, 
        --pedpedal_action as pedpedal_action,
        --pedpedal_visibility as pedpedal_visibility, 
        --pedpedal_location as pedpedal_location, 
        bac_result as bac_result
    from {{ source('raw_data', 'external_people') }}
)

select * from source