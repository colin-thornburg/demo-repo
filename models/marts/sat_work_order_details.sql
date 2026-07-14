{{ config(materialized='incremental', unique_key=['hk_work_order_h', 'src_ldts']) }}

{%- set src_pk = 'hk_work_order_h' -%}
{%- set src_hashdiff = 'hd_work_order_details_s' -%}
{%- set src_payload = ['facility_id', 'technician_id', 'work_order_status', 'priority_code', 'opened_ts', 'closed_ts'] -%}
{%- set src_extra_columns = [] -%}
{%- set src_eff = 'opened_ts' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_work_orders' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
