{{ config(materialized='incremental', unique_key=['hk_sales_daily_l', 'src_ldts']) }}

{%- set src_pk = 'hk_sales_daily_l' -%}
{%- set src_hashdiff = 'hd_sales_daily_s' -%}
{%- set src_payload = ['order_qty', 'gross_amount', 'line_count', 'currency_code'] -%}
{%- set src_extra_columns = [] -%}
{%- set src_eff = 'sales_date' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_sales' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
