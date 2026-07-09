with source as (
    select * from {{ ref('raw_providers') }}
),

renamed as (
    select
        provider_id,
        practice_name,
        signup_date,
        provider_specialty,
        billing_system,
        is_duplicate_account
    from source
    -- A practice can hold concurrent Alle Direct and GPO billing accounts under
    -- one provider_id, creating duplicate rows. Keep the Alle Direct record as
    -- canonical and drop the GPO duplicate.
    where is_duplicate_account = false
)

select * from renamed
