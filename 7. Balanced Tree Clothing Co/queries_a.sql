USE balanced_tree;

SELECT *
FROM product_details;
SELECT *
FROM sales;

-- A. High Level Sales Analysis

-- 1. What was the total quantity sold for all products?
-- For all products in total
SELECT 
	SUM(qty) AS quantity_sold
FROM sales;

-- For each product
SELECT
    pd.product_name AS product,
    SUM(s.qty) AS quantity_sold
FROM sales s
JOIN product_details pd
    ON s.prod_id = pd.product_id
GROUP BY product
ORDER BY quantity_sold DESC;

-- 2. What is the total generated revenue for all products before discounts?
-- For all products
SELECT 
	SUM(qty * price) AS total_revenue
FROM sales;

-- For each product
SELECT
    pd.product_name AS product,
    SUM(s.qty * s.price) AS total_revenue
FROM sales s
JOIN product_details pd
    ON s.prod_id = pd.product_id
GROUP BY product
ORDER BY total_revenue DESC;

-- 3. What was the total discount amount for all products?
-- For all products in total
SELECT
  ROUND(SUM(qty * price * discount / 100), 2) AS total_discount_amount
FROM sales;

-- For each product
SELECT
    pd.product_name AS product,
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2) AS total_discount_amount
FROM sales s
JOIN product_details pd
    ON s.prod_id = pd.product_id
GROUP BY product
ORDER BY total_discount_amount DESC;