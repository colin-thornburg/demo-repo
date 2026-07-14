{{ config(materialized='incremental', unique_key=['hk_core_shipment_l', 'src_ldts']) }}

{%- set src_pk = 'hk_core_shipment_l' -%}
{%- set src_hashdiff = 'hd_core_shipment_details_s' -%}
{%- set src_payload = ['shipment_ts', 'ship_from_facility_id', 'ship_to_dealer_id', 'shipment_status', 'carrier_code', 'tracking_number'] -%}
{%- set src_extra_columns = ['shipment_id'] -%}
{%- set src_eff = 'shipment_ts' -%}
{%- set src_ldts = 'src_ldts' -%}
{%- set src_source = 'src_source' -%}
{%- set source_model = 'stg_vault_reman_shipments' -%}

{{ automate_dv.sat(src_pk, src_hashdiff, src_payload, src_extra_columns, src_eff, src_ldts, src_source, source_model) }}
