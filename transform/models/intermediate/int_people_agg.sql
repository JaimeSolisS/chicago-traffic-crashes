SELECT
    -- IDENTITY --
    crash_record_id,
    -- AGG --
    count(*) as people_count,
    max(
        case
            when person_type = 'DRIVER' then 1 else 0
        end
    ) as has_driver,

    max(
        case
            when person_type = 'DRIVER'and driver_action != 'UNKNOWN' then 1 else 0
        end
    ) as has_known_driver_action,

    max(
        case
            when person_type = 'DRIVER' and physical_condition not in ('NORMAL', 'UNKNOWN') then 1 else 0
        end
    ) as driver_impairment_flag,

    max(
        case
            when person_type = 'DRIVER' and bac_result != 'UNKNOWN' then 1 else 0
        end
    ) as driver_bac_tested_flag,

    sum(
        case
            when injury_classification in ('FATAL', 'INCAPACITATING INJURY') then 1 else 0
        end
    ) as severe_injured_people_count

FROM {{ ref('stg_people') }}
GROUP BY crash_record_id