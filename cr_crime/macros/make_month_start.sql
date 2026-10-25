{% macro make_month_start(year, month) -%}
    {{ return(adapter.dispatch('make_month_start')(year, month)) }}
{%- endmacro %}

{% macro default__make_month_start(year, month) -%}
    make_date({{ year }}, {{ month }}, 1)
{%- endmacro %}

{% macro bigquery__make_month_start(year, month) -%}
    date({{ year }}, {{ month }}, 1)
{%- endmacro %}
