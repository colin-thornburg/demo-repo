with source as (
    select * from {{ ref('raw_orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_date,
        -- order_status: C = completed, R = returned, P = pending, X = cancelled
        order_status,
        order_total,
        discount_code
    from source
)

select * from renamed
