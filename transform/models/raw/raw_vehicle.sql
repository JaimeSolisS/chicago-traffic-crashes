with source as (
    select
        *
    from {{ source('raw_data', 'external_vehicles') }}
)

select * from source