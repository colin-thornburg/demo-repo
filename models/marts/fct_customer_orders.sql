with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

order_payments as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.order_total,
        p.amount as paid_amount,
        p.payment_status
    from orders o
    left join payments p on o.order_id = p.order_id
)

select
    c.customer_id,
    c.customer_tier,
    c.source_system,
    count(op.order_id) as order_count,
    sum(case when op.order_status = 'C' then op.order_total else 0 end) as completed_revenue,
    sum(case when op.payment_status = 'refunded' then op.paid_amount else 0 end) as refunded_amount
from customers c
left join order_payments op on c.customer_id = op.customer_id
group by 1, 2, 3
