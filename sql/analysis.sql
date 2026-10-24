-- Analysis queries on analytics.fct_crime_trends
-- Only complete years (2015-2025) are used; 2026 ends on 2026-10-08.

-- 1. Total reports per year and year-over-year change
-- Finding: peak in 2018, -33% in 2020 (pandemic), +21% in 2022, declining every year since.
WITH yearly AS (
    SELECT
        CAST(EXTRACT(YEAR FROM month_start) AS INTEGER) AS year,
        SUM(crime_count)                                AS total_crimes
    FROM analytics.fct_crime_trends
    WHERE month_start < '2026-01-01'
    GROUP BY 1
)
SELECT
    year,
    total_crimes,
    LAG(total_crimes) OVER (ORDER BY year) AS prev_year_total,
    ROUND(
        100.0 * (total_crimes - LAG(total_crimes) OVER (ORDER BY year))
        / LAG(total_crimes) OVER (ORDER BY year), 1
    ) AS yoy_pct
FROM yearly
ORDER BY year;

-- 2. Share of reports by province in 2025 (counts, not per-capita rates)
-- Finding: San Jose 39.4%, Alajuela 15.5%, Puntarenas 12.1%. Not adjusted for population.
WITH by_province AS (
    SELECT province, SUM(crime_count) AS crimes
    FROM analytics.fct_crime_trends
    WHERE month_start >= '2025-01-01'
      AND month_start <  '2026-01-01'
    GROUP BY province
)
SELECT
    province,
    crimes,
    ROUND(100.0 * crimes / SUM(crimes) OVER (), 1) AS pct_of_total,
    RANK() OVER (ORDER BY crimes DESC)             AS crime_rank
FROM by_province
ORDER BY crime_rank;

-- 3. Crime type composition, 2015 vs 2025
-- Finding: property crimes fell 9-42%, vehicle theft rose 32%, homicides rose 73% (575 -> 997).
WITH by_type AS (
    SELECT
        crime_type_en,
        SUM(crime_count) FILTER (WHERE month_start >= '2015-01-01' AND month_start < '2016-01-01') AS crimes_2015,
        SUM(crime_count) FILTER (WHERE month_start >= '2025-01-01' AND month_start < '2026-01-01') AS crimes_2025
    FROM analytics.fct_crime_trends
    GROUP BY crime_type_en
)
SELECT
    crime_type_en,
    crimes_2015,
    crimes_2025,
    ROUND(100.0 * (crimes_2025 - crimes_2015) / crimes_2015, 1) AS change_pct
FROM by_type
ORDER BY crimes_2015 DESC;

-- 4. Reports per 100,000 inhabitants by province, 2025 (population-adjusted)
-- Finding: Puntarenas 945, San Jose 933 (technical tie), Guanacaste 862; Alajuela drops from 2nd (count) to 6th (rate).
WITH by_province AS (
    SELECT
        province,
        SUM(crime_count) AS crimes,
        MAX(population)  AS population
    FROM analytics.fct_crime_rates
    WHERE year = 2025
      AND province <> 'DESCONOCIDO'
    GROUP BY province
)
SELECT
    province,
    crimes,
    population,
    ROUND(100000.0 * crimes / population, 1)                   AS crimes_per_100k,
    RANK() OVER (ORDER BY crimes DESC)                         AS rank_by_count,
    RANK() OVER (ORDER BY 100000.0 * crimes / population DESC) AS rank_by_rate
FROM by_province
ORDER BY rank_by_rate;

-- 5. Share of foreign victims by province, 2025
-- Finding: Puntarenas 24.3%, Guanacaste 19.1%, Cartago 5.7%. Tourists appear in reports but not in the resident population.
SELECT
    province,
    COUNT(*) AS reports,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE victim_nationality NOT IN ('COSTA RICA', 'DESCONOCIDO'))
        / COUNT(*), 1
    ) AS pct_foreign_victims
FROM analytics.int_police_reports_enriched
WHERE report_year = 2025
  AND province <> 'DESCONOCIDO'
GROUP BY province
ORDER BY pct_foreign_victims DESC;
