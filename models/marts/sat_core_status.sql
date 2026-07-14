{{ config(materialized='incremental', unique_key=['hk_core_h', 'src_ldts']) }}

{%- set src_pk = 'hk_core_h' -%}
{%- set src_hashdiff = 'hd_core_status_s' -%}
{%- set src_payload = ['core_part_number', 'received_date', 'received_facility_id', 'dealer_id', 'customer_id', 'condition_code', 'current_status'] -%}
{%- set src_extra_columns = [] -%}
{%- set src_eff = 'received_date' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_cores' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
