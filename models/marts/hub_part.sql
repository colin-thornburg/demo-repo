{{ config(materialized='incremental', unique_key='hk_part_h') }}

{%- set src_pk = 'hk_part_h' -%}
{%- set src_nk = 'part_number' -%}
{%- set src_extra_columns = [] -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_parts' -%}

{{ automate_dv.hub(src_pk, src_nk, src_extra_columns, src_ldts, src_source, source_model) }}
