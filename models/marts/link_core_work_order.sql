{{ config(materialized='incremental', unique_key='hk_core_work_order_l') }}

{%- set src_pk = 'hk_core_work_order_l' -%}
{%- set src_fk = ['hk_core_h', 'hk_work_order_h'] -%}
{%- set src_extra_columns = ['core_serial_number', 'work_order_number'] -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_work_orders' -%}

{{ automate_dv.link(src_pk, src_fk, src_extra_columns, src_ldts, src_source, source_model) }}
