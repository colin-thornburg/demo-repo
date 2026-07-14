{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_work_order_h': 'work_order_number',
    'hk_core_h': 'core_serial_number',
    'hk_part_h': 'part_number',
    'hk_work_order_part_l': ['work_order_number', 'part_number'],
    'hd_work_order_part_usage_s': {
        'is_hashdiff': true,
        'columns': ['transaction_id', 'core_serial_number', 'transaction_ts', 'transaction_type', 'quantity', 'unit_cost', 'reason_code']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_reman_part_transactions',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
