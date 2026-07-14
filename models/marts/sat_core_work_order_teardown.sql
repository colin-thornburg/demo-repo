{{ config(materialized='incremental', unique_key=['hk_core_work_order_l', 'src_ldts']) }}

{%- set src_pk = 'hk_core_work_order_l' -%}
{%- set src_hashdiff = 'hd_core_work_order_teardown_s' -%}
{%- set src_payload = ['teardown_event_id', 'event_ts', 'station_id', 'technician_id', 'teardown_step_code', 'component_area', 'disposition_code', 'failure_mode_code', 'measurement_value', 'measurement_unit', 'requires_replacement_flag', 'notes'] -%}
{%- set src_extra_columns = [] -%}
{%- set src_eff = 'event_ts' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_teardown_events' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
