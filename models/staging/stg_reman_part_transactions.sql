{{ config(materialized='view') }}

select
    cast(transaction_id as varchar) as transaction_id,
    cast(work_order_number as varchar) as work_order_number,
    cast(core_serial_number as varchar) as core_serial_number,
    cast(part_number as varchar) as part_number,
    cast(transaction_ts as timestamp) as transaction_ts,
    cast(transaction_type as varchar) as transaction_type,
    cast(quantity as number(18, 0)) as quantity,
    cast(unit_cost as number(18, 2)) as unit_cost,
    cast(reason_code as varchar) as reason_code,
    cast(load_datetime as timestamp) as load_datetime,
    'raw_reman_part_transactions' as record_source
from {{ ref('raw_reman_part_transactions') }}
