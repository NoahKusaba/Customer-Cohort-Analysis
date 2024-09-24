-- Filter by start date
WITH cohort_data AS (
  SELECT *
  FROM project_schema.online_retail_ii
  WHERE invoicedate >= '{{ var('initial_period_start') }}'
),

-- Data cleaning
cleaned_data AS (
  SELECT DISTINCT
    stockcode,
    invoice,
    customer_id,
    invoicedate,
    quantity,
    price,
    ROW_NUMBER() OVER (PARTITION BY stockcode, invoice, quantity ORDER BY invoicedate) AS dup
  FROM cohort_data
  WHERE quantity > 0 AND price > 0 AND customer_id IS NOT NULL
),

deduplicated_data AS (
  SELECT *
  FROM cleaned_data
  WHERE dup = 1
),

-- First purchase per customer (cohort date calculation)
customer_first_purchase AS (
  SELECT 
    customer_id, 
    MIN(invoicedate) AS first_purchase,
    DATEFROMPARTS(YEAR(MIN(invoicedate)), MONTH(MIN(invoicedate)), 1) AS cohort_date
  FROM deduplicated_data
  GROUP BY customer_id
),

-- Add customer cohort data to each purchase
customer_purchase_per_cohort AS (
  SELECT 
    d.*,
    c.cohort_date,
    YEAR(d.invoicedate) AS invoice_year,
    MONTH(d.invoicedate) AS invoice_month,
    YEAR(c.cohort_date) AS cohort_year,
    MONTH(c.cohort_date) AS cohort_month
  FROM deduplicated_data d
  LEFT JOIN customer_first_purchase c
    ON d.customer_id = c.customer_id
),

-- Calculate cohort index (months since first purchase)
cohort_indexes AS (
  SELECT 
    *,
    (invoice_year - cohort_year) * 12 + (invoice_month - cohort_month) + 1 AS cohort_index
  FROM customer_purchase_per_cohort
)

-- Final output
SELECT DISTINCT
  customer_id,
  cohort_date,
  cohort_index
FROM cohort_indexes
ORDER BY cohort_date, cohort_index, customer_id
