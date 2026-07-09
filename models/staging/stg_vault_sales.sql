{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_customer_h': 'customer_id',
    'hk_product_h': 'product_id',
    'hk_store_h': 'store_id',
    'hk_sales_daily_l': ['sales_date', 'customer_id', 'product_id', 'store_id'],
    'hd_sales_daily_s': {
        'is_hashdiff': true,
        'columns': ['order_qty', 'gross_amount', 'line_count', 'currency_code']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_sales_events',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
