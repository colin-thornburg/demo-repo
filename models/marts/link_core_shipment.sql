{{ config(materialized='incremental', unique_key='hk_core_shipment_l') }}

{%- set src_pk = 'hk_core_shipment_l' -%}
{%- set src_fk = ['hk_core_h', 'hk_work_order_h'] -%}
{%- set src_extra_columns = ['shipment_id', 'core_serial_number', 'work_order_number'] -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_shipments' -%}

{{ automate_dv.link(src_pk, src_fk, src_extra_columns, src_ldts, src_source, source_model) }}
