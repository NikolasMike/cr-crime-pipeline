-- Each yearly file should only contain reports dated in that year.
select *
from {{ source('raw', 'police_reports') }}
where source_year != extract(year from cast(report_date as date))
