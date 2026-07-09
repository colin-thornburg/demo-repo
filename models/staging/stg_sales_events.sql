{{ config(materialized='view') }}

with order_events as (
    select
        cast(date_trunc('day', cast(o.order_ts as timestamp)) as date) as sales_date,
        cast(o.customer_id as varchar) as customer_id,
        cast(ol.product_id as varchar) as product_id,
        cast(o.store_id as varchar) as store_id,
        sum(coalesce(ol.quantity, 0)) as order_qty,
        sum(coalesce(ol.quantity, 0) * coalesce(ol.unit_price, 0)) as gross_amount_local,
        count(*) as line_count
    from {{ ref('raw_orders') }} o
    inner join {{ ref('raw_order_lines') }} ol
        on o.order_id = ol.order_id
    where o.order_status = 'COMPLETED'
    group by 1, 2, 3, 4
),

return_events as (
    select
        cast(date_trunc('day', cast(r.return_ts as timestamp)) as date) as sales_date,
        cast(r.customer_id as varchar) as customer_id,
        cast(rl.product_id as varchar) as product_id,
        cast(r.store_id as varchar) as store_id,
        -sum(coalesce(rl.quantity, 0)) as order_qty,
        -sum(coalesce(rl.quantity, 0) * coalesce(rl.unit_price, 0)) as gross_amount_local,
        0 as line_count
    from {{ ref('raw_returns') }} r
    inner join {{ ref('raw_return_lines') }} rl
        on r.return_id = rl.return_id
    group by 1, 2, 3, 4
),

all_events as (
    select * from order_events
    union all
    select * from return_events
),

fx_enriched as (
    select
        e.sales_date,
        e.customer_id,
        e.product_id,
        e.store_id,
        e.order_qty,
        e.line_count,
        e.gross_amount_local * coalesce(fx.rate_to_usd, 1.0) as gross_amount,
        coalesce(s.currency_code, 'USD') as currency_code,
        current_timestamp() as load_datetime,
        'sales_fact_daily' as record_source
    from all_events e
    left join {{ ref('raw_stores') }} s
        on e.store_id = cast(s.store_id as varchar)
    left join {{ ref('ref_fx_daily_rates') }} fx
        on e.sales_date = cast(fx.rate_date as date)
       and coalesce(s.currency_code, 'USD') = fx.currency_code
),

final as (
    select
        sales_date,
        customer_id,
        product_id,
        store_id,
        sum(order_qty) as order_qty,
        sum(gross_amount) as gross_amount,
        sum(line_count) as line_count,
        min(load_datetime) as load_datetime,
        min(record_source) as record_source,
        min(currency_code) as currency_code
    from fx_enriched
    group by 1, 2, 3, 4
)

select *
from final
