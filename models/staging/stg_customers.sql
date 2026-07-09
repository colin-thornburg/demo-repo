with source as (
    select * from {{ ref('raw_customers') }}
),

renamed as (
    select
        customer_id,
        signup_date,
        customer_tier,
        source_system,
        is_duplicate_customer
    from source
    -- Keep the non-metronome record when a customer_id is duplicated across
    -- billing providers (concurrent Stripe + Metronome accounts share a customer_id).
    where is_duplicate_customer = false
)

select * from renamed
