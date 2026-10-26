{% macro logical_or(column) -%}
    {{ return(adapter.dispatch('logical_or')(column)) }}
{%- endmacro %}

{% macro default__logical_or(column) -%}
    bool_or({{ column }})
{%- endmacro %}

{% macro bigquery__logical_or(column) -%}
    logical_or({{ column }})
{%- endmacro %}
