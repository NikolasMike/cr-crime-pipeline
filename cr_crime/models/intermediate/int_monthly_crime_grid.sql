-- Grain: one row per month, province and crime type, whether or not any crime was reported

with bounds as (

    select
        cast(date_trunc('month', min(report_date)) as date)  as first_month,
        cast(date_trunc('month', max(report_date)) as date)  as last_month
    from {{ ref('int_police_reports_enriched') }}

),

months as (

    select cast(generate_series(first_month, last_month, interval '1 month') as date) as month_start
    from bounds

),

provinces as (

    select distinct province
    from {{ ref('int_police_reports_enriched') }}

),

crime_types as (

    select crime_type_en
    from {{ ref('crime_type_translation') }}

),

grid as (

    select
        months.month_start,
        provinces.province,
        crime_types.crime_type_en
    from months
    cross join provinces
    cross join crime_types

)

select * from grid
