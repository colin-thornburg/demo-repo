select
    customer_id
from {{ ref('dim_customer') }}
where is_current = 'Y'
group by 1
having count(*) > 1
