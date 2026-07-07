select
    customer_id
from {{ ref('raw_addresses') }}
where address_type = 'PRIMARY'
group by 1
having count(*) > 1
