{{ config(materialized='incremental', unique_key=['hk_core_work_order_l', 'src_ldts']) }}

{%- set src_pk = 'hk_core_work_order_l' -%}
{%- set src_hashdiff = 'hd_core_work_order_inspection_s' -%}
{%- set src_payload = ['inspection_id', 'inspection_ts', 'inspector_id', 'inspection_result', 'wear_score', 'crack_flag', 'contamination_flag', 'notes'] -%}
{%- set src_extra_columns = [] -%}
{%- set src_eff = 'inspection_ts' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_inspections' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
