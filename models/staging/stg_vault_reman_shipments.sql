{{ config(materialized='view') }}

{%- set hashed_columns = {
    'hk_core_h': 'core_serial_number',
    'hk_work_order_h': 'work_order_number',
    'hk_core_shipment_l': ['core_serial_number', 'work_order_number', 'shipment_id'],
    'hd_core_shipment_details_s': {
        'is_hashdiff': true,
        'columns': ['shipment_ts', 'ship_from_facility_id', 'ship_to_dealer_id', 'shipment_status', 'carrier_code', 'tracking_number']
    }
} -%}

{%- set derived_columns = {
    'src_ldts': 'load_datetime',
    'src_source': 'record_source'
} -%}

{{ automate_dv.stage(
    include_source_columns=true,
    source_model='stg_reman_shipments',
    hashed_columns=hashed_columns,
    derived_columns=derived_columns
) }}
