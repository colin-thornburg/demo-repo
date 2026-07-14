{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_work_order_h': 'work_order_number',
    'hk_core_h': 'core_serial_number',
    'hk_core_work_order_l': ['core_serial_number', 'work_order_number'],
    'hd_work_order_details_s': {
        'is_hashdiff': true,
        'columns': ['facility_id', 'technician_id', 'work_order_status', 'priority_code', 'opened_ts', 'closed_ts']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_reman_work_orders',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
