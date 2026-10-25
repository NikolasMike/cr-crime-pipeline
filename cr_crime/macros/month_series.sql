{% macro month_series(start_col, end_col) -%}
    {{ return(adapter.dispatch('month_series')(start_col, end_col)) }}
{%- endmacro %}

{% macro default__month_series(start_col, end_col) -%}
    generate_series({{ start_col }}, {{ end_col }}, interval '1 month')
{%- endmacro %}

{% macro bigquery__month_series(start_col, end_col) -%}
    unnest(generate_date_array({{ start_col }}, {{ end_col }}, interval 1 month))
{%- endmacro %}
