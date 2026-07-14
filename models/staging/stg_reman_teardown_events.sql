{{ config(materialized='view') }}

select
    cast(teardown_event_id as varchar) as teardown_event_id,
    cast(core_serial_number as varchar) as core_serial_number,
    cast(work_order_number as varchar) as work_order_number,
    cast(event_ts as timestamp) as event_ts,
    cast(station_id as varchar) as station_id,
    cast(technician_id as varchar) as technician_id,
    cast(teardown_step_code as varchar) as teardown_step_code,
    cast(component_area as varchar) as component_area,
    cast(disposition_code as varchar) as disposition_code,
    cast(failure_mode_code as varchar) as failure_mode_code,
    cast(measurement_value as number(18, 2)) as measurement_value,
    cast(measurement_unit as varchar) as measurement_unit,
    upper(cast(requires_replacement_flag as varchar)) as requires_replacement_flag,
    cast(notes as varchar) as notes,
    cast(load_datetime as timestamp) as load_datetime,
    'raw_reman_teardown_events' as record_source
from {{ ref('raw_reman_teardown_events') }}
