{{ config(materialized='view') }}

with core_parts as (
    select distinct
        hk_part_h,
        core_part_number as part_number,
        src_ldts,
        src_source
    from {{ ref('stg_vault_reman_cores') }}
    where core_part_number is not null
),

transaction_parts as (
    select distinct
        hk_part_h,
        part_number,
        src_ldts,
        src_source
    from {{ ref('stg_vault_reman_part_transactions') }}
    where part_number is not null
)

select * from core_parts
union
select * from transaction_parts
