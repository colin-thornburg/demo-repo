{{ config(materialized='view') }}

select
    cast(work_order_number as varchar) as work_order_number,
    cast(core_serial_number as varchar) as core_serial_number,
    cast(opened_ts as timestamp) as opened_ts,
    cast(closed_ts as timestamp) as closed_ts,
    cast(facility_id as varchar) as facility_id,
    cast(technician_id as varchar) as technician_id,
    cast(work_order_status as varchar) as work_order_status,
    cast(priority_code as varchar) as priority_code,
    cast(load_datetime as timestamp) as load_datetime,
    'raw_reman_work_orders' as record_source
from {{ ref('raw_reman_work_orders') }}
