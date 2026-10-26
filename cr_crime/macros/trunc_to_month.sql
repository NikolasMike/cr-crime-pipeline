{% macro trunc_to_month(date_expr) -%}
    {{ return(adapter.dispatch('trunc_to_month')(date_expr)) }}
{%- endmacro %}

{% macro default__trunc_to_month(date_expr) -%}
    date_trunc('month', {{ date_expr }})
{%- endmacro %}

{% macro bigquery__trunc_to_month(date_expr) -%}
    date_trunc({{ date_expr }}, month)
{%- endmacro %}
