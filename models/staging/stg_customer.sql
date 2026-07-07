{{ config(materialized='view') }}

with customers as (
    select
        customer_id,
        first_name,
        last_name,
        lower(trim(email)) as email,
        regexp_replace(phone, '[^0-9]', '') as phone,
        account_status,
        coalesce(credit_limit, 0) as credit_limit,
        cast(last_modified_ts as timestamp) as last_modified_ts
    from {{ ref('raw_customers') }}
),

primary_addresses as (
    select
        customer_id,
        address_line1,
        city,
        state_province,
        postal_code,
        coalesce(country_code, 'US') as country_code
    from {{ ref('raw_addresses') }}
    where address_type = 'PRIMARY'
),

joined as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.account_status,
        c.credit_limit,
        a.address_line1,
        a.city,
        a.state_province,
        a.postal_code,
        a.country_code,
        c.last_modified_ts,
        dateadd(month, 18, c.last_modified_ts) as churned_at
    from customers c
    left join primary_addresses a
        on c.customer_id = a.customer_id
),

final as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        case
            when account_status = 'ACTIVE'
                and churned_at <= current_timestamp()
                then 'CHURNED'
            else account_status
        end as account_status,
        credit_limit,
        address_line1,
        city,
        state_province,
        postal_code,
        country_code,
        last_modified_ts,
        churned_at,
        case
            when account_status = 'ACTIVE'
                and churned_at <= current_timestamp()
                then churned_at
            else last_modified_ts
        end as effective_updated_at
    from joined
)

select *
from final
