with source as (
    select
        *
    from {{ source('raw_data', 'external_people') }}
)

select * from source