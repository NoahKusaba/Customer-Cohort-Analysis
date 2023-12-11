{%- set my_table = "STACKLESS.PIVOT_SOURCE" -%}

{%- set my_query -%}
select distinct COHORT_INDEX FROM {{my_table}} order by COHORT_INDEX ASC
{%- endset -%}
{%- set results = run_query(my_query) -%}

{%- if execute -%}
{%- set items = results.columns[0].values() -%}
{%- endif -%}

select * from {{my_table}}
    pivot(
        count(CUSTOMER_ID) for COHORT_INDEX in {{items}}
    )
ORDER BY COHORT_DATE DESC



