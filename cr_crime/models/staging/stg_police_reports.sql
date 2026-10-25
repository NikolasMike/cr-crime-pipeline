with source as (

    select * from {{ source('raw', 'police_reports') }}

),

cleaned as (

    select
        upper(trim(crime_type)) as crime_type,
        upper(trim(modus_operandi)) as modus_operandi,
        cast(report_date as date) as report_date,
        upper(trim(victim_type)) as victim_type,
        upper(trim(victim_subtype)) as victim_subtype,
        upper(trim(victim_age_group)) as victim_age_group,
        upper(trim(victim_nationality)) as victim_nationality,
        upper({{ collapse_whitespace('province') }}) as province,
        upper({{ collapse_whitespace('canton') }}) as canton,
        upper({{ collapse_whitespace('district') }}) as district,
        source_year
    from source

)

select * from cleaned
