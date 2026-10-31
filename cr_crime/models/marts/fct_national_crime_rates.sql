-- Grain: one row per year and crime type, national level.
-- Rates come from summed counts over summed population,
-- never from adding province-level rates.

with provincial as (

    select
        year,
        crime_type_en,
        crime_count,
        is_partial_year
    from {{ ref('fct_crime_rates') }}
    where population is not null

),

national_crimes as (

    select
        year,
        crime_type_en,
        sum(crime_count) as crime_count,
        {{ logical_or("is_partial_year") }} as is_partial_year
    from provincial
    group by year, crime_type_en

),

national_population as (

    select
        year,
        sum(population) as population
    from {{ ref('province_population') }}
    group by year

),

final as (

    select
        national_crimes.year,
        national_crimes.crime_type_en,
        national_crimes.crime_count,
        national_population.population,
        round(100000.0 * national_crimes.crime_count / national_population.population, 1) as crimes_per_100k,
        national_crimes.is_partial_year
    from national_crimes
    left join national_population
        on national_crimes.year = national_population.year

)

select * from final
