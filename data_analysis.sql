-- table creation

CREATE TABLE customers (
	CustomerID varchar primary key,
	firstname varchar,
	lastname varchar,
	gender varchar,
	birthdate date,
	city varchar, 
	date_joined date
);

CREATE TABLE products (
	ProductID varchar primary key,
	productname varchar,
	category varchar,
	subcategory varchar,
	unitprice numeric,
	costprice numeric
);

CREATE TABLE  stores (
	StoreID varchar primary key,
	storename varchar,
	city varchar,
	region varchar
);

CREATE TABLE transactions (
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

SELECT * FROM transactions
WHERE customerid in ('C045', 'C170', 'C073');

-- derived columns

SELECT quantity * (pr.unitprice * (1-discount)) as salesamount
FROM transactions tr
JOIN products pr
USING (productid);

SELECT (unitprice - costprice) * quantity as profit
FROM transactions tr
JOIN products pr
USING (productid);

-- CUSTOMER INSIGHTS

-- Demographic Distribution
-- gender
SELECT
	gender,
	COUNT(*) total
FROM customers
GROUP BY gender;

--age
WITH cte_age AS (
SELECT
	EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birthdate) as age
FROM customers)
SELECT
	CASE
		WHEN age BETWEEN 18 AND 25 THEN '18-25'
		WHEN age BETWEEN 26 AND 35 THEN '26-35'
		WHEN age BETWEEN 36 AND 50 THEN '36-50'
		WHEN age BETWEEN 51 AND 64 THEN '51-64'
		ELSE '65+'
	END AS age_group,
	COUNT(*) as num_of_customer
FROM cte_age
GROUP BY age_group
ORDER BY num_of_customer DESC;

-- Customer lifetime
SELECT 
    c.customerid,
    c.date_joined,
    rd.recent AS last_transaction,
    AGE(rd.recent, c.date_joined) AS lifetime
FROM customers c
JOIN (
    SELECT DISTINCT ON (customerid)
           customerid,
           date AS recent
    FROM transactions
    ORDER BY customerid, date DESC
) rd
  ON c.customerid = rd.customerid
WHERE AGE(rd.recent, c.date_joined) > interval '0'
ORDER BY lifetime DESC;

-- Top 3 Customers
SELECT
	c.customerid,
	CONCAT(firstname, ' ', lastname) "name",
	SUM((p.unitprice * t.quantity) * t.discount) "revenue"
FROM customers c
JOIN transactions t
ON c.customerid = t.customerid
JOIN products p
ON t.productid = p.productid
GROUP BY c.customerid
ORDER BY revenue DESC
LIMIT 3;

-- Monthly Sales
SELECT
	TO_CHAR(date, 'FMMonth') as month,
	ROUND(SUM((p.unitprice * t.quantity) * t.discount), 2) as revenue
FROM transactions t
JOIN products p
ON t.productid = p.productid
GROUP BY month
ORDER BY revenue DESC;

-- 10 Top-selling products
SELECT
	productname,
	category,
	SUM(t.quantity) as total_sold
FROM products p
JOIN transactions t
ON p.productid = t.productid
GROUP BY productname, category
ORDER BY total_sold DESC
LIMIT 10;

-- Top Category and sub-category
SELECT 
    CASE 
        WHEN GROUPING(p.category) = 1 THEN 'ALL Categories'
        ELSE p.category
    END AS category,
    CASE 
        WHEN GROUPING(p.subcategory) = 1 THEN 'ALL Subcategories'
        ELSE p.subcategory
    END AS subcategory,
    SUM(t.quantity) AS total_sold
FROM products p
JOIN transactions t 
    ON p.productid = t.productid
GROUP BY ROLLUP (p.category, p.subcategory)
ORDER BY 
    GROUPING(p.category), 
    p.category,
    GROUPING(p.subcategory),
    p.subcategory;
