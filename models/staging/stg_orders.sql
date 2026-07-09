with source as (
    select * from {{ ref('raw_orders') }}
),

renamed as (
    select
        order_id,
        provider_id,
        order_date,
        -- order_status: S = shipped, R = returned, B = backordered, C = cancelled
        order_status,
        product_family,
        units_ordered,
        promo_code
    from source
)

select * from renamed