{{ config(materialized='incremental', unique_key=['hk_work_order_part_l', 'src_ldts']) }}

{%- set src_pk = 'hk_work_order_part_l' -%}
{%- set src_hashdiff = 'hd_work_order_part_usage_s' -%}
{%- set src_payload = ['transaction_id', 'core_serial_number', 'transaction_ts', 'transaction_type', 'quantity', 'unit_cost', 'reason_code'] -%}
{%- set src_extra_columns = [] -%}
{%- set src_eff = 'transaction_ts' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_part_transactions' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
