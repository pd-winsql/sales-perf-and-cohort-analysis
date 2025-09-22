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

-- Store with the highest income
SELECT COUNT(*) as num_of_trans, s.storename
FROM transactions t
JOIN stores s
ON t.storeid = s.storeid
GROUP BY s.storename
ORDER BY num_of_trans DESC;

