{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_core_h': 'core_serial_number',
    'hk_work_order_h': 'work_order_number',
    'hk_core_work_order_l': ['core_serial_number', 'work_order_number'],
    'hd_core_work_order_inspection_s': {
        'is_hashdiff': true,
        'columns': ['inspection_id', 'inspection_ts', 'inspector_id', 'inspection_result', 'wear_score', 'crack_flag', 'contamination_flag', 'notes']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_reman_inspections',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
