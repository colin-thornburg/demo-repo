{{ config(materialized='table') }}

select
    md5(customer_id || '|' || to_varchar(dbt_valid_from, 'YYYY-MM-DD HH24:MI:SS.FF')) as customer_sk,
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    account_status,
    credit_limit,
    address_line1,
    city,
    state_province,
    postal_code,
    country_code,
    last_modified_ts as src_modified_ts,
    churned_at,
    dbt_valid_from as effective_start_ts,
    dbt_valid_to as effective_end_ts,
    iff(dbt_valid_to = to_timestamp_ntz('9999-12-31'), 'Y', 'N') as is_current
from {{ ref('dim_customer_snapshot') }}
