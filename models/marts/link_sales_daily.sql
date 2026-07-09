{{ config(materialized='incremental', unique_key='hk_sales_daily_l') }}

{%- set src_pk = 'hk_sales_daily_l' -%}
{%- set src_fk = ['hk_customer_h', 'hk_product_h', 'hk_store_h'] -%}
{%- set src_extra_columns = ['sales_date', 'customer_id', 'product_id', 'store_id'] -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_sales' -%}

{{ automate_dv.link(src_pk, src_fk, src_extra_columns, src_ldts, src_source, source_model) }}
