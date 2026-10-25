-- Grain: one row per month, province and crime type (zeros included)

with grid as (

    select * from {{ ref('int_monthly_crime_grid') }}

),

counts as (

    select
        month_start,
        province,
        crime_type_en,
        crime_count
    from {{ ref('fct_monthly_crimes') }}

),

filled as (

    select
        grid.month_start,
        grid.province,
        grid.crime_type_en,
        coalesce(counts.crime_count, 0) as crime_count
    from grid
    left join counts
        on
            grid.month_start = counts.month_start
            and grid.province = counts.province
            and grid.crime_type_en = counts.crime_type_en

),

with_windows as (

    select
        month_start,
        province,
        crime_type_en,
        crime_count,
        lag(crime_count, 12) over (
            partition by province, crime_type_en
            order by month_start
        ) as crime_count_prev_year,
        round(avg(crime_count) over (
            partition by province, crime_type_en
            order by month_start
            rows between 2 preceding and current row
        ), 1) as moving_avg_3m,
        month_start = max(month_start) over () as is_latest_month
    from filled

),

final as (

    select
        *,
        case
            when crime_count_prev_year > 0
                then round(100.0 * (crime_count - crime_count_prev_year) / crime_count_prev_year, 1)
        end as yoy_change_pct
    from with_windows

)

select * from final
