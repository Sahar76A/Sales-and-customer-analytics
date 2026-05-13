- CREATE TABLE STATEMENTS (Assuming CSVs are imported into these tables):
CREATE TABLE orders (
    order_id        INT PRIMARY KEY,
    customer_id     INT,
    order_date      DATE,
    total_amount    DECIMAL(10,2)
);
CREATE TABLE order_items (
    order_id        INT,
    product_id      INT,
    quantity        INT,
    unit_price      DECIMAL(10,2),
	sales			INT,
	discounts		DECIMAL(10,2)
);
CREATE TABLE products (
    product_id      INT PRIMARY KEY,
    category        VARCHAR(100),
    product_name    VARCHAR(200),
    unit_cost       DECIMAL(10,2)
);
--============================================================
-- Hi. Let's start with question #3: Data Quality Checks (part a) to check data first.
-- Here we check Duplicate values, Missing values (Null), and Referential integrity for each table. 

-- Let's start with order table:
-- Check the duplicate values (based on order_id and customer_id values) in order table
SELECT o.order_id, o.customer_id, COUNT(*) AS occurrence_count
FROM orders o
GROUP BY o.order_id, o.customer_id
HAVING COUNT(*) > 1;

-- Check the Missing values (Null)  in order table
SELECT *
FROM orders o
WHERE o.order_id IS NULL OR o.customer_id IS NULL OR 
	  o.order_date IS NULL OR O.total_amount IS NULL; 

-- Check the Referential integrity (Orders without matching order_items) in order table
SELECT o.order_id
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;
--------------------------------------------------------------
--Now Let's check Duplicate values, Missing values (Null), and Referential integrity in order_items table:

--Check the duplicate values (based on order_id and product_id values) in order_items table
SELECT oi.order_id, oi.product_id, COUNT(*) AS occurrence_count
FROM order_items oi
GROUP BY oi.order_id, oi.product_id
HAVING COUNT(*) > 1;

-- Check the Missing values (Null) in order_items table
SELECT *
FROM order_items oi
WHERE oi.order_id IS NULL OR oi.product_id IS NULL OR 
	  oi.quantity IS NULL OR oi.unit_price IS NULL OR
	  oi.sales	  IS NULL OR oi.discounts  IS NULL;

-- Check the Referential integrity (Order items without matching an Order) in order_items table
SELECT oi.order_id
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check the Referential integrity (Order items without matching a product) in order_items table
SELECT oi.product_id
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
--------------------------------------------------------------
--Now Let's check Duplicate values, Missing values (Null), and Referential integrity in product table:

--Check the duplicate values (product_id values) in product table
SELECT p.product_id, COUNT(*) AS occurrence_count
FROM products p
GROUP BY p.product_id
HAVING COUNT(*) > 1;

-- Check the Missing values (Null) in product table
SELECT *
FROM products p
WHERE p.product_id	  IS NULL OR p.category  IS NULL OR 
	  p.product_name  IS NULL OR p.unit_cost IS NULL;

-- Check the Referential integrity (Products without matching an Order item) in product table
SELECT p.product_id
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;
--------------------------------------------------------------
-- Now let's start question 3: Data Quality Checks (part b) to clean data and solve these issues before doing any calculation.

-- Solving issue #1 (Duplicated Values in order_items table) by removing those records:
WITH CTE_order_items_Duplicates AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY  oi.order_id, oi.product_id ORDER BY (SELECT NULL)) as Occurance
    FROM
        order_items oi)
DELETE FROM CTE_order_items_Duplicates
WHERE Occurance > 1;

-- Solving issue #2 (Unknown product in product table) by removing that record:
DELETE FROM products
WHERE product_id = -1

-- Solving issue #3 (Data Type mismatch in "unit_cost" column of products table) by removing prefix and change data type:
UPDATE products
SET unit_cost = REPLACE(unit_cost, '$', '');
ALTER TABLE products
ALTER COLUMN unit_cost DOUBLE NOT NULL;

--Solving issue #4 (Wrong value in "sales" column) by correcting it: 
-- At first it seems that column 'sales' is the multiplication of 'quantity' and 'unit_price' 
-- but in some records it is not. Let's check it firts:
WITH Sales_Check_CTE AS (
SELECT *, (oi.quantity * oi.unit_price) AS check_sales
FROM order_items oi)
SELECT *
FROM Sales_Check_CTE
WHERE sales <> check_sales);
-- Now let's correct it:
UPDATE oi
SET
    oi.sales = oi.quantity* oi.unit_price
FROM
    order_items oi
--============================================================
--Now the data is almost clean. Let's get back to the quesion #1 part a: 

-- 1. SALES METRICS:
-- part (a)
/*
Metrics:
gross_revenue = quantity * unit_price 
net_revenue = gross_revenue - discount 
cost = unit_cost * quantity
*/
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_gross_revenue,
   (SUM(oi.quantity * oi.unit_price) -oi.discounts) AS total_net_revenue,
    SUM(oi.quantity * p.unit_cost) AS total_cost
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY p.category	
--------------------------------------------------------------
-- part (b) gross_margin_perc
/*
Metrics:
gross_margin_per =(total_gross_revenue -  total_cost)/total_gross_revenue
net_revenue = (total_net_revenue - total_cost)/total_net_revenue 
*/
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_gross_revenue,
   (SUM(oi.quantity * oi.unit_price) -oi.discounts) AS total_net_revenue,
    SUM(oi.quantity * p.unit_cost) AS total_cost,
   ((SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.unit_cost))
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0) * 100) AS gross_margin_perc,
   (((SUM(oi.quantity * oi.unit_price) -oi.discounts) - SUM(oi.quantity * p.unit_cost))
        / NULLIF((SUM(oi.quantity * oi.unit_price) -oi.discounts), 0) * 100) AS net_margin_perc
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY gross_margin_perc DESC;

--============================================================
-- Now Let's start quesion #2 part (a) Top 2 customers by total spending:
SELECT TOP(2)
    o.customer_id,
    SUM(o.total_amount) AS total_spent
FROM orders o
GROUP BY o.customer_id
ORDER BY total_spent DESC
--------------------------------------------------------------
-- And now question #2 part b Average order value per customer:

-- Here we should consider that each customer might have more than one order, 
-- so here we need an aggregation to calculate the average order value for each cusotmer:
SELECT
    o.customer_id,
    AVG(o.total_amount) AS customer_avg_order
FROM orders o
GROUP BY o.customer_id
ORDER BY customer_avg_order DESC;

--============================================================
-- 5. FREQUENTLY PURCHASED PRODUCTS (TOP 3 PAIRS)

-- Here we need to use self-join on order_items then join products table two times to each order_items tables.
SELECT TOP(3)
    p1.product_id AS product_a,
    p2.product_id AS product_b,
    COUNT(DISTINCT oi1.order_id) AS frequency
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_id, p2.product_id
ORDER BY frequency DESC;

