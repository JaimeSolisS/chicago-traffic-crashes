 SELECT
    -- IDENTITY --
    crash_record_id,
    -- AGG --
    count(*) as vehicle_count,
    max(
        case
            when vehicle_defect != 'UNKNOWN' then 1 else 0
        end
    ) as vehicle_defect_flag,

    max(
        case
            when vehicle_type not in ('UNKNOWN/NA', 'UNKNOWN') then 1 else 0
        end
    ) as has_known_vehicle_type,

    max(
        case
            when maneuver not in ('UNKNOWN/NA', 'UNKNOWN') then 1 else 0
        end
    ) as has_known_maneuver

FROM {{ ref('stg_vehicle') }}
GROUP BY crash_record_id