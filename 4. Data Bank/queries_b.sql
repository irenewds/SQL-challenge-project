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
SELECT
    month_number,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        MONTH(txn_date) AS month_number,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM data_bank.customer_transactions
    GROUP BY customer_id, MONTH(txn_date)
) monthly_activity
WHERE deposit_count > 1
  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month_number
ORDER BY month_number;

-- 4. What is the closing balance for each customer at the end of the month?
WITH monthly_transactions AS (
    SELECT
        customer_id,
        YEAR(txn_date) AS year_number,
        MONTH(txn_date) AS month_number,
        SUM(
            CASE
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type IN ('purchase', 'withdrawal') THEN - txn_amount
                ELSE 0
            END
        ) AS net_monthly_change
    FROM customer_transactions
    GROUP BY customer_id, YEAR(txn_date), MONTH(txn_date)
)

SELECT
    customer_id,
    year_number,
    month_number,
    SUM(net_monthly_change) OVER (
        PARTITION BY customer_id
        ORDER BY year_number, month_number
    ) AS closing_balance
FROM monthly_transactions
ORDER BY customer_id, year_number, month_number;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?