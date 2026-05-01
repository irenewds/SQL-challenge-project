USE data_bank;

SELECT *
FROM regions;
SELECT *
FROM customer_nodes
LIMIT 10;
SELECT *
FROM customer_transactions
LIMIT 10;

-- B. Customer Transactions

-- 1. What is the unique count and total amount for each transaction type?
SELECT
    txn_type,
    COUNT(*) AS unique_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH deposits AS (
SELECT
    customer_id,
    COUNT(*) AS count,
    SUM(txn_amount) AS sum
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)

SELECT
    ROUND(AVG(count)) AS average_count,
    ROUND(AVG(sum)) AS average_amount
FROM deposits;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

-- 4. What is the closing balance for each customer at the end of the month?

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?