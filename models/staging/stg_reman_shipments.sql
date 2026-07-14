{{ config(materialized='view') }}

select
    cast(shipment_id as varchar) as shipment_id,
    cast(core_serial_number as varchar) as core_serial_number,
    cast(work_order_number as varchar) as work_order_number,
    cast(shipment_ts as timestamp) as shipment_ts,
    cast(ship_from_facility_id as varchar) as ship_from_facility_id,
    cast(ship_to_dealer_id as varchar) as ship_to_dealer_id,
    cast(shipment_status as varchar) as shipment_status,
    cast(carrier_code as varchar) as carrier_code,
    cast(tracking_number as varchar) as tracking_number,
    cast(load_datetime as timestamp) as load_datetime,
    'raw_reman_shipments' as record_source
from {{ ref('raw_reman_shipments') }}
