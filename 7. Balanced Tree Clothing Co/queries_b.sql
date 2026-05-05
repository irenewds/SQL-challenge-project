USE balanced_tree;

SELECT *
FROM product_details;
SELECT *
FROM sales;

-- B. Transaction Analysis

-- 1. How many unique transactions were there?
SELECT
    COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;

-- 2. What is the average unique products purchased in each transaction?
WITH transaction_cte AS (
    SELECT
        txn_id,
        COUNT(DISTINCT prod_id) AS product_count
    FROM sales
    GROUP BY txn_id
)

SELECT
    ROUND(AVG(product_count)) AS avg_unique_products
FROM transaction_cte;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

-- 4. What is the average discount value per transaction?
WITH cte_transaction AS (
	SELECT
		txn_id,
		SUM(price * qty * discount)/100 AS total_discount
	FROM sales
	GROUP BY txn_id
)
SELECT
	ROUND(AVG(total_discount)) AS avg_unique_products
FROM cte_transaction;

-- 5. What is the percentage split of all transactions for members vs non-members?

-- 6. What is the average revenue for member transactions and non-member transactions?
WITH cte_transaction AS (
	SELECT
        member,
		txn_id,
		SUM(price * qty) AS total_revenue
	FROM sales
	GROUP BY member, txn_id
)

SELECT
    member,
	ROUND(AVG(total_revenue)) AS avg_revenue
FROM cte_transaction
GROUP BY member
ORDER BY avg_revenue;