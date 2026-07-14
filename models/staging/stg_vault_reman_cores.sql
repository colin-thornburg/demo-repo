{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_core_h': 'core_serial_number',
    'hk_part_h': 'core_part_number',
    'hd_core_status_s': {
        'is_hashdiff': true,
        'columns': ['core_part_number', 'received_date', 'received_facility_id', 'dealer_id', 'customer_id', 'condition_code', 'current_status']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_reman_cores',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
