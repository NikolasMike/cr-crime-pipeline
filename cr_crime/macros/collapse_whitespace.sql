{% macro collapse_whitespace(column) -%}
    {{ return(adapter.dispatch('collapse_whitespace')(column)) }}
{%- endmacro %}

{% macro default__collapse_whitespace(column) -%}
    regexp_replace(trim({{ column }}), '\s+', ' ', 'g')
{%- endmacro %}

{% macro bigquery__collapse_whitespace(column) -%}
    regexp_replace(trim({{ column }}), r'\s+', ' ')
{%- endmacro %}
