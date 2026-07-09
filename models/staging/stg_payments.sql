with source as (
    select * from {{ ref('raw_payments') }}
),

renamed as (
    select
        payment_id,
        order_id,
        provider,
        payment_method,
        amount_cents / 100.0 as amount,
        status as payment_status
    from source
)

select * from renamed
