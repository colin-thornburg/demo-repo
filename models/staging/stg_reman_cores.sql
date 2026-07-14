{{ config(materialized='view') }}

select
    cast(core_serial_number as varchar) as core_serial_number,
    cast(part_number as varchar) as core_part_number,
    cast(received_date as date) as received_date,
    cast(received_facility_id as varchar) as received_facility_id,
    cast(dealer_id as varchar) as dealer_id,
    cast(customer_id as varchar) as customer_id,
    cast(condition_code as varchar) as condition_code,
    cast(current_status as varchar) as current_status,
    cast(load_datetime as timestamp) as load_datetime,
    'raw_reman_cores' as record_source
from {{ ref('raw_reman_cores') }}
