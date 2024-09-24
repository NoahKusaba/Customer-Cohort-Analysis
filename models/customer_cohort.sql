-- Get the source data
WITH pivot_source_table AS ( 
  SELECT * 
  FROM {{ ref('pivot_source') }}
)

-- Build dynamic query for cohort indexes
{%- set cohort_query -%}
  SELECT DISTINCT cohort_index 
  FROM {{ ref('pivot_source') }} 
  ORDER BY cohort_index ASC
{%- endset -%}

{%- set cohort_results = run_query(cohort_query) -%}

{%- if execute -%}
  {%- set cohort_items = cohort_results.columns[0].values() -%}
{%- else -%}
  {%- set cohort_items = [] -%}  -- Handles compilation mode (dbt compile) when no execution
{%- endif -%}

-- Pivot the data based on cohort index
SELECT * 
FROM pivot_source_table
PIVOT (
  COUNT(customer_id) FOR cohort_index IN ({{ cohort_items | join(', ') }})
)
ORDER BY cohort_date DESC
