with source as (
    select * from {{ ref('raw_shipments') }}
),

renamed as (
    select
        shipment_id,
        order_id,
        ship_date,
        units_shipped,
        units_sampled,
        cold_chain_flag
    from source
)

select * from renamed