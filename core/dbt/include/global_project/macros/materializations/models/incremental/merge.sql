{% macro get_merge_sql(target, source, unique_key, dest_columns, predicates) -%}
  {{ adapter.dispatch('get_merge_sql', 'dbt')(target, source, unique_key, dest_columns, predicates) }}
{%- endmacro %}

{% macro default__get_merge_sql(target, source, unique_key, dest_columns, predicates) -%}
    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}
    {%- set update_columns = config.get('merge_update_columns', default = dest_columns | map(attribute="quoted") | list) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none }}

    merge into {{ target }} as DBT_INTERNAL_DEST
        using {{ source }} as DBT_INTERNAL_SOURCE
        on {{ predicates }}

    {% if unique_key %}
    when matched then update set
        {% for column_name in update_columns -%}
            {{ column_name }} = DBT_INTERNAL_SOURCE.{{ column_name }}
            {%- if not loop.last %}, {%- endif %}
        {%- endfor %}
    {% endif %}

    when not matched then insert
        ({{ dest_cols_csv }})
    values
        ({{ dest_cols_csv }})

{% endmacro %}


{% macro get_delete_insert_merge_sql(target, source, unique_key, dest_columns, predicates) -%}
  {{ adapter.dispatch('get_delete_insert_merge_sql', 'dbt')(target, source, unique_key, dest_columns, predicates) }}
{%- endmacro %}

{% macro default__get_delete_insert_merge_sql(target, source, unique_key, dest_columns, predicates) -%}

    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}

    {% if unique_key is not none %}
    delete from {{ target }}
    where ({{ unique_key }}) in (
        select ({{ unique_key }})
        from {{ source }}
    )
    {{ predicates }}
    ;

    {%- endif %}

    insert into {{ target }} ({{ dest_cols_csv }})
    (
        select {{ dest_cols_csv }}
        from {{ source }}
    )

{%- endmacro %}


{% macro get_insert_overwrite_merge_sql(target, source, dest_columns, predicates, include_sql_header=false) -%}
  {{ adapter.dispatch('get_insert_overwrite_merge_sql', 'dbt')(target, source, dest_columns, predicates, include_sql_header) }}
{%- endmacro %}

{% macro default__get_insert_overwrite_merge_sql(target, source, dest_columns, predicates, include_sql_header) -%}
    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none and include_sql_header }}

    merge into {{ target }} as DBT_INTERNAL_DEST
        using {{ source }} as DBT_INTERNAL_SOURCE
        on FALSE

    when not matched by source
        {% if predicates %} and {{ predicates }} {% endif %}
        then delete

    when not matched then insert
        ({{ dest_cols_csv }})
    values
        ({{ dest_cols_csv }})

{% endmacro %}
