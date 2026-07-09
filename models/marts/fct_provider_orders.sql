with providers as (
    select * from {{ ref('stg_providers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

shipments as (
    select * from {{ ref('stg_shipments') }}
),

order_shipments as (
    select
        o.order_id,
        o.provider_id,
        o.product_family,
        o.order_status,
        o.units_ordered,
        s.units_shipped,
        s.units_sampled
    from orders o
    left join shipments s on o.order_id = s.order_id
)

select
    p.provider_id,
    p.practice_name,
    p.provider_specialty,
    p.billing_system,
    count(os.order_id) as order_count,
    -- Net units billed = shipped, excluding free samples. Only S (shipped)
    -- orders count toward recognized product revenue.
    sum(case when os.order_status = 'S'
             then coalesce(os.units_shipped, 0) - coalesce(os.units_sampled, 0)
             else 0 end) as units_dispensed
from providers p
left join order_shipments os on p.provider_id = os.provider_id
group by 1, 2, 3, 4
