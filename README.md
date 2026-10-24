# Costa Rica Police Reports: an Analytics Engineering Pipeline

An end-to-end ELT pipeline built on Costa Rica's open police statistics (2015-2026): raw CSVs loaded into PostgreSQL, modelled with dbt in layers (staging, intermediate, marts), tested, documented, and analysed with window functions.

I built it to practise the full analytics engineering workflow on real, messy public data, not to produce a polished dataset.

## Data source

- **Dataset:** Estadisticas Policiales, Poder Judicial de Costa Rica open data portal (one CSV per year, 2015-2026).
- **Size:** 578,049 reports, from 2015-01-01 to 2026-10-08. Each row is one crime report (crime type, modality, date, victim type, victim age group, victim nationality, province, canton, district).
- **Scope:** only six crime types: theft (hurto), robbery (asalto), burglary (robo), vehicle theft, vehicle break-in and homicide.
- **Population (for rates):** INEC-Costa Rica, Estimaciones y proyecciones subnacionales de poblacion 2000-2050, June 2025. Total population by province at 30 June of each year, reshaped from INEC's Excel table into a dbt seed. Values from 2025 onward are projections.

## Stack

PostgreSQL 16, Python 3.12 (uv, psycopg2), dbt-postgres 1.12, dbt_utils, Bash.

## Architecture

```
raw.police_reports
        |
stg_police_reports  (clean text, cast dates)
        |
int_police_reports_enriched  <--  crime_type_translation (seed)
        |                                  
        +--> fct_monthly_crimes --+
        |                         |
        +--> int_monthly_crime_grid --> fct_crime_trends
```

| Layer | Model | Grain (one row per...) | Materialization |
|---|---|---|---|
| staging | `stg_police_reports` | police report | view |
| intermediate | `int_police_reports_enriched` | police report | view |
| intermediate | `int_monthly_crime_grid` | month x province x crime type (all combinations) | view |
| marts | `fct_monthly_crimes` | month x province x crime type (only months with reports) | table |
| marts | `fct_crime_trends` | month x province x crime type (zeros filled) | table |
| marts | `fct_crime_rates` | year x province x crime type, with reports per 100,000 inhabitants | table |

`fct_crime_trends` adds year-over-year change (`LAG`), a 3-month moving average and an `is_latest_month` flag.

## Data quality issues found and how they were handled

| Problem | Handling |
|---|---|
| CSVs have no header row | Column names assigned explicitly in the table definition |
| Files are encoded in latin1, not UTF-8 | Read with the right encoding in the loader |
| One column is always empty | Loaded to `raw`, dropped in staging |
| 24 rows have an extra comma inside country names (e.g. "CONGO, REPUBLICA DEMOCRATICA DEL") | Loader merges the split fields back into one |
| Age group is padded with spaces; "Desconocido" and "DESCONOCIDO" both appear | `trim` + `upper` in staging |
| Double spaces in place names | Collapsed with a regex in staging |
| Months with zero reports do not exist as rows | A month x province x crime type grid fills them with 0 before any window function |
| 2026 is incomplete (ends on 2026-10-08) | Flagged with `is_latest_month`; analysis uses full years only |

Raw data is never modified: `raw.police_reports` is a faithful copy and all cleaning happens in dbt.

## Tests

22 dbt tests, all passing: `not_null`, `unique`, `accepted_values`, `relationships`, `dbt_utils.unique_combination_of_columns` (grain checks), `dbt_utils.accepted_range`, and one singular test that checks the enrichment join neither adds nor loses rows.

## Findings

Queries are in `sql/analysis.sql`. Full years only (2015-2025).

1. **Total reports peaked in 2018** (61,464), fell 33% in 2020 (pandemic), rebounded 21% in 2022, and have declined every year since (39,388 in 2025).
2. **San Jose concentrates 39% of reports in 2025**, followed by Alajuela (15.5%) and Puntarenas (12.1%). These are counts, not rates.
3. **Property crimes fell, homicides rose.** Theft -34%, robbery -36%, burglary -42%, vehicle break-in -9%; vehicle theft +32% and homicides +73% (575 to 997) between 2015 and 2025.

4. **Adjusted for population, Puntarenas has the highest rate in 2025** (945 reports per 100,000 inhabitants), technically tied with San Jose (933) and followed by Guanacaste (862). Alajuela drops from 2nd by count to 6th by rate (568) and Cartago is the lowest (532). The provinces with the highest rates also have the highest share of foreign victims (Puntarenas 24%, Guanacaste 19%, Cartago 6%), which suggests tourists inflate the rates because the INEC population only counts residents.

A possible reading of (3): homicide is the crime least dependent on a victim choosing to report it, so its rise is a more reliable signal than the fall in thefts, which may partly reflect people reporting less. These data suggest this but cannot prove it.

## Limitations

- These are **police reports, not crimes**. A change can come from crime, from reporting behaviour, or from registration practices.
- Rates use the INEC resident population (30 June estimates; 2025 onward are projections). Tourists appear in the reports but not in the denominator, which likely inflates rates in tourist provinces such as Puntarenas and Guanacaste. A foreign victim is not necessarily a tourist.
- Only six crime types are covered.
- The English crime-type labels are approximations of legal categories (e.g. `ROBO` -> Burglary, `ASALTO` -> Robbery), kept in a seed so they are easy to review.
- `modus_operandi` has overlapping categories (e.g. "POR DESCUIDO" and "DESCUIDO") that were not harmonised.
- Month-level counts for small groups (e.g. homicides in one province) are very volatile; avoid reading single-month changes as trends.

## How to reproduce

```bash
sudo service postgresql start
psql -U postgres -c "CREATE DATABASE crime;"
psql -U postgres -d crime -c "CREATE SCHEMA raw;"
psql -U postgres -d crime -f sql/create_raw.sql

uv sync
./scripts/download_police.sh
uv run python src/load_raw.py

cd cr_crime
uv run dbt deps
uv run dbt build          # seeds, models and tests
uv run dbt docs generate && uv run dbt docs serve --port 8080
```

`cr_crime/profiles.yml` contains a local-only password for a throwaway development database. Use environment variables for anything real.

## Repository structure

```
scripts/download_police.sh    download the 12 yearly CSVs
src/load_raw.py               load CSVs into raw.police_reports
sql/create_raw.sql            raw table definition
sql/analysis.sql              analysis queries and findings
cr_crime/                     dbt project (models, seeds, tests)
```

## Next steps

- Rates per canton (INEC also publishes canton-level population) and a tourism-adjusted denominator.
- Use the larger Poder Judicial datasets (judicial case duration, notifications) in a local DuckDB setup.

## Source

Poder Judicial de Costa Rica, open data portal (Estadisticas Policiales). Check the portal for the terms of use.

Population: INEC-Costa Rica, Estimaciones y proyecciones subnacionales de poblacion 2000-2050, June 2025.
