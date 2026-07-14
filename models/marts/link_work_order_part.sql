{{ config(materialized='incremental', unique_key='hk_work_order_part_l') }}

{%- set src_pk = 'hk_work_order_part_l' -%}
{%- set src_fk = ['hk_work_order_h', 'hk_part_h'] -%}
{%- set src_extra_columns = ['work_order_number', 'part_number'] -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_part_transactions' -%}

{{ automate_dv.link(src_pk, src_fk, src_extra_columns, src_ldts, src_source, source_model) }}
