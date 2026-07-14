{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_core_h': 'core_serial_number',
    'hk_work_order_h': 'work_order_number',
    'hk_core_work_order_l': ['core_serial_number', 'work_order_number'],
    'hd_core_work_order_teardown_s': {
        'is_hashdiff': true,
        'columns': ['teardown_event_id', 'event_ts', 'station_id', 'technician_id', 'teardown_step_code', 'component_area', 'disposition_code', 'failure_mode_code', 'measurement_value', 'measurement_unit', 'requires_replacement_flag', 'notes']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_reman_teardown_events',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
