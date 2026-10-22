with reports as (

    select * from {{ ref('stg_police_reports') }}

),

crime_types as (

    select * from {{ ref('crime_type_translation') }}

),

enriched as (

    select
        reports.report_date,
        cast(extract(year from reports.report_date) as integer)   as report_year,
        cast(extract(month from reports.report_date) as integer)  as report_month,
        reports.crime_type                                        as crime_type_es,
        crime_types.crime_type_en,
        reports.modus_operandi,
        reports.victim_type,
        reports.victim_subtype,
        reports.victim_age_group,
        reports.victim_nationality,
        reports.province,
        reports.canton,
        reports.district
    from reports
    left join crime_types
        on reports.crime_type = crime_types.crime_type_es

)

select * from enriched
