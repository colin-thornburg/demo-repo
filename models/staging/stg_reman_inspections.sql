{{ config(materialized='view') }}

select
    cast(inspection_id as varchar) as inspection_id,
    cast(core_serial_number as varchar) as core_serial_number,
    cast(work_order_number as varchar) as work_order_number,
    cast(inspection_ts as timestamp) as inspection_ts,
    cast(inspector_id as varchar) as inspector_id,
    cast(inspection_result as varchar) as inspection_result,
    cast(wear_score as number(18, 0)) as wear_score,
    upper(cast(crack_flag as varchar)) as crack_flag,
    upper(cast(contamination_flag as varchar)) as contamination_flag,
    cast(notes as varchar) as notes,
    cast(load_datetime as timestamp) as load_datetime,
    'raw_reman_inspections' as record_source
from {{ ref('raw_reman_inspections') }}
