-- Grain: one row per year, province and crime type

with trends as (

    select
        cast(extract(year from month_start) as integer) as year,
        province,
        crime_type_en,
        crime_count,
        is_latest_month
    from {{ ref('fct_crime_trends') }}

),

yearly as (

    select
        year,
        province,
        crime_type_en,
        sum(crime_count) as crime_count,
        {{ logical_or("is_latest_month") }} as is_partial_year
    from trends
    group by year, province, crime_type_en

),

population as (

    select
        province,
        year,
        population
    from {{ ref('province_population') }}

),

final as (

    select
        yearly.year,
        yearly.province,
        yearly.crime_type_en,
        yearly.crime_count,
        population.population,
        round(100000.0 * yearly.crime_count / population.population, 1) as crimes_per_100k,
        yearly.is_partial_year
    from yearly
    left join population
        on
            yearly.province = population.province
            and yearly.year = population.year

)

select * from final
