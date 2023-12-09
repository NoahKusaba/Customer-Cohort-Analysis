WITH cohort_data AS (
  SELECT
    Customer_ID,
    datediff({{ var('time_grain') }}, date_trunc({{ var('period_size') }}, dateadd( Day,  -1 , INVOICEDATE)), INVOICEDATE) AS cohort_period,
    COUNT(DISTINCT Invoice) AS invoices
  FROM
    STACKLESS.ONLINE_RETAIL_II
  WHERE
    INVOICEDATE >= '{{ var('initial_period_start') }}'
  GROUP BY
    Customer_ID, cohort_period
)

SELECT
  cohort_period,
  COUNT(DISTINCT Customer_ID) AS customer_count,
  SUM(invoices) AS total_invoices
FROM
  cohort_data
GROUP BY
  cohort_period
ORDER BY
  cohort_period