-- totol records = 541909
select * 
from online_retail_og;
-- records with InvoiceNo and CustomerID not null and UnitPrice > 0 = 397884
with transform_01
as
(
	select *, ROW_NUMBER() OVER(partition by InvoiceNo, StockCode, Quantity order by InvoiceDate) rw
	from online_retail_og 
	where InvoiceNo is not null and CustomerID is not null and UnitPrice <> 0
),
-- deduped_records = 392669
deduped_records as
(
	select *
	from transform_01
	where rw = 1
)
select 
	InvoiceNo as invoice_no,
	StockCode as product_code,
	Description product_name,
	Quantity as quantity,
	InvoiceDate as invoice_date,
	UnitPrice as unit_price,
	CustomerID as customer_id,
	Country as country
into 
	#online_retail_pro
from 
	deduped_records;

-- clean records = 392669 
select *
from #online_retail_pro;

--------------------------- Cohort Analysis---------------------------------------
-- unique identifier = customer_id
-- Initital Invoice Date (first_purchase_date)
-- cohort_date in yyyy-MM


select 
	customer_id,
	min(invoice_date) first_purchase_date,
	FORMAT(min(invoice_date), 'yyyy-MM-01') cohort_date
into #cohort_tbl
from #online_retail_pro
group by customer_id;

-- create cohort index
select
	m.*,
	c.cohort_date,
	DATEDIFF(Month, cohort_date, FORMAT(invoice_date, 'yyyy-MM-dd')) + 1 cohort_index
into #cohort_user_retention
from 
	#online_retail_pro m
	join #cohort_tbl c on m.customer_id = c.customer_id

select
	*
into #cohort_pivot
from
	(select Distinct
		customer_id,
		cohort_date Cohort,
		cohort_index
	from #cohort_user_retention) tbl
Pivot
(
	Count(customer_id)
	for cohort_index in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13])
) as pivot_tbl

select
	*
from
	#cohort_pivot

