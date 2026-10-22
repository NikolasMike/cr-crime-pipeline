-- Fails if the join in int_police_reports_enriched adds or loses rows
select *
from (
    select
        (select count(*) from {{ ref('stg_police_reports') }})           as staging_rows,
        (select count(*) from {{ ref('int_police_reports_enriched') }})  as enriched_rows
) as counts
where staging_rows <> enriched_rows
