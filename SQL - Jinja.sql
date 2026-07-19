-- The basic syntax
    -- Jinja has theree types of delimiters:
        -- {% ... %} for statements
        -- {{ ... }} for expressions to print to the template output
        -- {# ... #} for comments
-- Why dbt is built on Jinja
    -- dbt uses Jinja to allow for dynamic SQL generation, 
    -- which means you can write SQL that adapts based on variables, c
    -- onditions, and loops. This makes your SQL more flexible and reusable.
        -- ref() and source() are Jinja functions that help you reference other models and sources in your dbt project.

-- Common paterns
-- 1. Variables: You can define variables in your dbt project and use them in your SQL models. 
    -- -- For example, you can define a variable for a table name or a date range and use it in your SQL queries.
    {% set payment_mentods = ['ach','wire','card'] %}

    select 
        {% for method in payment_methods %} -- start of the for loop
        sum(case when payment_type = '{{ method }}' then amount end) as {{ method }}_total
        {% if not loop.last %}, {% endif %} -- if the is not the last item, output a comma; if it is the last item, output nothing
        {% endfor %} -- end of the for loop
    from {{ref('stg_transactions')}} -- ref() is a Jinja function that helps you reference other models in your dbt project. In this case, it references the stg_transactions model.

    -- this would be like:
    select 
        sum(case when payment_type = 'ach' then amount end) as ach_total,
        sum(case when payment_type = 'wire' then amount end) as wire_total,
        sum(case when payment_type = 'card' then amount end) as card_total
    from stg_transactions

    -- alternative pattern - loop.first and loop.last
    select
        {% for method in payment_methods %}
        {% if not loop.first %}, {% endif %} -- if the is not the first item, output a comma; if it is the first item, output nothing
        sum(case when payment_type = '{{ method }}' then amount end) as {{ method }}_total
        {% endfor %}
    from {{ref('stg_transactions')}}

-- 2. Conditions - pure sql statement doesn't have if statement, so need to use jinja to add if statement
    select *
    from {{ ref('stg_transactions')}}
    {% if target.name == 'dev' %}
    limit 1000
    {% endif %}

-- 3. Macros (reusable functions) - you can define a macro in your dbt project and use it in your SQL models. 
    -- For example, you can define a macro to calculate the total amount for a specific payment type and use it in your SQL queries.
    -- macros/calculate_total.sql
    {% macro calculate_total(payment_type) %} -- define the macro name and variable
        sum(case when payment_type = '{{ payment_type }}' then amount end) -- the macro body, which is the SQL code that will be generated when the macro is called
    {% endmacro %}

    -- models/transactions.sql
    select 
        {{ calculate_total('ach') }} as ach_total,
        {{ calculate_total('wire') }} as wire_total,
        {{ calculate_total('card') }} as card_total
    from {{ ref('stg_transactions')}} -- ref() is a Jinja function that helps you reference other models in your dbt project. In this case, it references the stg_transactions model.

-- 4. Incremental models - you can define an incremental model in your dbt project and use it to only process new or updated data.
    {{ config(materialized='incremental', unique_key='transaction_id') }} -- configure the model to be incremental and set the unique key to transaction_id. Uni

    select *
    from {{ ref('stg_transactions') }}
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}