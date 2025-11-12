-- table creation

CREATE TABLE IF NOT EXISTS customers (
	CustomerID varchar primary key,
	firstname varchar,
	lastname varchar,
	gender varchar,
	birthdate date,
	city varchar, 
	date_joined date
);

CREATE TABLE IF NOT EXISTS products (
	ProductID varchar primary key,
	productname varchar,
	category varchar,
	subcategory varchar,
	unitprice numeric,
	costprice numeric
);

CREATE TABLE IF NOT EXISTS stores (
	StoreID varchar primary key,
	storename varchar,
	city varchar,
	region varchar
);

CREATE TABLE IF NOT EXISTS transactions (
	TransactionID varchar primary key,
	date date,
	CustomerID varchar references customers(CustomerID),
	ProductID varchar references products(ProductID),
	StoreID varchar references stores(StoreID),
	quantity numeric,
	discount numeric,
	paymentmethod varchar
);

-- data are imported

-- table viewing
SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM stores;

SELECT * FROM transactions;

-- derived columns

SELECT quantity * (pr.unitprice * (1-discount)) as salesamount
FROM transactions tr
JOIN products pr
USING (productid);

SELECT (pr.unitprice - pr.costprice) * quantity as profit
FROM transactions tr
JOIN products pr
USING (productid);

-- date range
SELECT
	min(date) start,
	max(date) end
FROM transactions;

-- total sales & profit
SELECT
	t.date,
	p.category,
	p.subcategory,
	s.region,
	ROUND(SUM(t.quantity * (p.unitprice * (1-t.discount))), 2) as salesAmount,
	ROUND(SUM((p.unitprice - p.costprice) * quantity), 2) as profit
FROM transactions t
JOIN products p
USING (productid)
JOIN stores s
USING (storeid)
GROUP BY t.date, p.category, p.subcategory, s.region
ORDER BY t.date;

-- TOP 5 products by total sales
SELECT
	p.productname,
	ROUND(SUM(quantity * (unitprice * (1-discount))), 2) as total_sales
FROM transactions
JOIN products p
USING (productid)
GROUP BY productname
ORDER BY total_sales DESC
LIMIT 5;

-- sales by region
SELECT
	s.region,
	ROUND(SUM(t.quantity * (p.unitprice * (1-t.discount))), 2) as total_sales,
	ROUND(SUM((p.unitprice - p.costprice) * quantity), 2) as profit
FROM transactions t
JOIN products p USING (productid)
JOIN stores s USING (storeid)
GROUP BY s.region
ORDER BY total_sales DESC;


-- cleaned fact table
CREATE MATERIALIZED VIEW IF NOT EXISTS sales_fact AS
SELECT
    t.transactionid,
    t.date,
    t.customerid,
    p.productid,
    s.storeid,
    s.region,
    p.category,
    p.subcategory,
    p.productname,
    p.unitprice,
    p.costprice,
    t.quantity,
    t.discount,
    ROUND(p.unitprice * t.quantity * (1 - t.discount), 2) AS sales_amount,
    ROUND((p.unitprice - p.costprice) * t.quantity, 2) AS profit
FROM transactions t
JOIN products p ON t.productid = p.productid
JOIN stores s   ON t.storeid = s.storeid;

REFRESH MATERIALIZED VIEW sales_fact;

-- overall KPIs
SELECT
	ROUND(SUM(sales_amount), 2) as total_sales,
	ROUND(SUM(profit), 2) as total_profit,
	ROUND(SUM(profit)/SUM(sales_amount)*100,2) as profit_margin_pct,
	ROUND(AVG(sales_amount), 2) as avg_transaction_value
FROM sales_fact;

-- monthly sales trend
SELECT
	DATE_TRUNC('month', date)::date as month,
	ROUND(SUM(sales_amount), 2) as total_sales,
	ROUND(SUM(profit), 2) total_profit,
	ROUND(SUM(profit)/SUM(sales_amount),2) as profit_margin
FROM sales_fact
GROUP BY month
ORDER BY month;

-- year over year growth
WITH monthly_sales AS (
	SELECT
		DATE_TRUNC('MONTH', date)::date as month,
		SUM(sales_amount) as total_sales
	FROM sales_fact
	GROUP BY month
)
SELECT
	month,
	total_sales,
	ROUND(
		(total_sales - LAG(total_sales) OVER (ORDER BY month))
		/ NULLIF(LAG(total_sales)OVER (ORDER BY month), 0) * 100, 2
	) as growth_pct
FROM monthly_sales
ORDER BY month;

-- top 5 customers
SELECT
	c.customerid,
	c.firstname || ' ' || c.lastname as customer_name,
	ROUND(SUM(s.sales_amount), 2) as total_sales,
	ROUND(SUM(s.profit), 2) as total_profit
FROM sales_fact s
JOIN customers c
USING (customerid)
GROUP BY c.customerid, customer_name
ORDER BY total_sales DESC
LIMIT 5;

-- cohort analysis
CREATE MATERIALIZED VIEW IF NOT EXISTS customer_first_purchase AS
SELECT
	customerid,
	MIN(DATE_TRUNC('month', date))::date AS first_purchase_month
FROM sales_fact
GROUP BY customerid;

CREATE MATERIALIZED VIEW IF NOT EXISTS customer_cohort AS
SELECT
	f.customerid,
	fp.first_purchase_month,
	DATE_TRUNC('month', f.date)::date as purchase_month,
	EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', f.date), fp.first_purchase_month)) as months_since_first,
	SUM(f.sales_amount) as total_sales
FROM sales_fact f
JOIN customer_first_purchase fp
USING (customerid)
GROUP BY f.customerid, fp.first_purchase_month, purchase_month, months_since_first
ORDER BY fp.first_purchase_month, months_since_first;