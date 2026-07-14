{{ config(materialized='incremental', unique_key='hk_core_h') }}

{%- set src_pk = 'hk_core_h' -%}
{%- set src_nk = 'core_serial_number' -%}
{%- set src_extra_columns = [] -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_cores' -%}

{{ automate_dv.hub(src_pk, src_nk, src_extra_columns, src_ldts, src_source, source_model) }}
