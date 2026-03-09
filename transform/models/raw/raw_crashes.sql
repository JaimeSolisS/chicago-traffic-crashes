with source as (
    select
        *
    from {{ source('raw_data', 'external_crashes') }}
)

select * from source