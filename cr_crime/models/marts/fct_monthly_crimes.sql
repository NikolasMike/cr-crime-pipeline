-- Grain: one row per month, province and crime type

with enriched as (

    select * from {{ ref('int_police_reports_enriched') }}

),

monthly as (

    select
        {{ make_month_start("report_year", "report_month") }} as month_start,
        report_year,
        report_month,
        province,
        crime_type_en,
        count(*) as crime_count
    from enriched
    group by report_year, report_month, province, crime_type_en

)

select * from monthly
