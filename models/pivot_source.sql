-- Filters by Start Date
WITH cohort_data AS (
  SELECT
  *
  FROM 
  STACKLESS.ONLINE_RETAIL_II
  WHERE INVOICEDATE <= '{{ var('initial_period_start') }}'
),  
-- Data Cleaning 
quantity_unit_price as  (
  SELECT * FROM cohort_data
  where QUANTITY > 0 and PRICE > 0 and CUSTOMER_ID IS not NUll
),  

dedup_data as (

  select * , ROW_NUMBER() OVER(PARTITION BY STOCKCODE, INVOICE, QUANTITY order by INVOICEDATE) as dup
  from quantity_unit_price
), 

cleaned_data as ( 
select *  from dedup_data where dup = 1
),

-- Split by Period Size 
customer_firstPurchase AS (
  select CUSTOMER_ID, 
  min(INVOICEDATE) AS FIRST_PURCHASE,
  DATEFROMPARTS(YEAR(MIN(INVOICEdATE)), MONTH(MIN(INVOICEDATE)), 1) AS COHORT_DATE
  FROM cleaned_data
  GROUP BY CUSTOMER_ID
) ,
CUSTOMER_PURCHASE_PER_COHORT AS (

  select  m.*, 
          c.COHORT_DATE,
					year(m.InvoiceDate) invoice_year,
					month(m.InvoiceDate) invoice_month,
					year(c.Cohort_Date) cohort_year,
					month(c.Cohort_Date) cohort_month
    from cleaned_data as m
    left join customer_firstPurchase as c 
      on m.CUSTOMER_ID = c.CUSTOMER_ID

), 
-- Create Cohort Index 
COHORT_INDEXES AS (
  select mm.*, 
        (year_diff * 12 + month_diff + 1 ) as cohort_index
        from
  (SELECT *, 
  (invoice_year - cohort_year) as year_diff, 
  (invoice_month - cohort_month) as month_diff 
  FROM CUSTOMER_PURCHASE_PER_COHORT) as mm
),  PIVOT_TABLE as ( 

    select distinct 
      CUSTOMER_ID,
      COHORT_DATE,
      COHORT_INDEX 
      FROM COHORT_INDEXES

) 
select * from PIVOT_TABLE
