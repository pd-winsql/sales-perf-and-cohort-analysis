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

-- table viewing
SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM stores;

SELECT * FROM transactions;

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
WITH recent_date as(
	SELECT 
		customerid, 
		MAX(date) as recent
	FROM transactions
	GROUP BY customerid
)
SELECT 
	c.customerid,
	c.date_joined,
	rd.recent as last_transaction,
	AGE(rd.recent, c.date_joined) as lifetime_days
FROM customers c
JOIN recent_date rd
ON c.customerid = rd.customerid;