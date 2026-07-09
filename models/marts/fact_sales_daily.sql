{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=['sales_date', 'customer_sk', 'product_id', 'store_id'],
        on_schema_change='sync_all_columns'
    )
}}

with sales_window as (
    select
        sales_date,
        customer_id,
        product_id,
        store_id,
        order_qty,
        gross_amount,
        line_count
    from {{ ref('stg_sales_events') }}
    {% if is_incremental() %}
        where sales_date >= (
            select coalesce(dateadd(day, -3, max(sales_date)), to_date('1900-01-01'))
            from {{ this }}
        )
    {% endif %}
),

customer_dim as (
    select
        customer_id,
        customer_sk,
        is_current,
        effective_start_ts,
        effective_end_ts
    from {{ ref('dim_customer') }}
),

final as (
    select
        s.sales_date,
        d.customer_sk,
        s.product_id,
        s.store_id,
        s.order_qty,
        s.gross_amount,
        s.line_count,
        cast(null as number) as batch_id
    from sales_window s
    left join customer_dim d
        on s.customer_id = d.customer_id
       and d.is_current = 'Y'
)

select *
from final
