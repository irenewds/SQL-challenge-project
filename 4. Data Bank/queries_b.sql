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
WITH monthly_txn AS (
    SELECT
        customer_id,
        DATE_FORMAT(txn_date, '%Y-%m-01') AS txn_month,
        SUM(CASE
            WHEN txn_type = 'deposit' THEN  txn_amount
            ELSE -txn_amount
        END) AS monthly_net
    FROM customer_transactions
    GROUP BY customer_id, DATE_FORMAT(txn_date, '%Y-%m-01')
),
running_balance AS (
    SELECT
        customer_id, txn_month,
        SUM(monthly_net) OVER (
            PARTITION BY customer_id ORDER BY txn_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS closing_balance
    FROM monthly_txn
),
first_last AS (
    SELECT DISTINCT
        customer_id,
        FIRST_VALUE(closing_balance) OVER (
            PARTITION BY customer_id ORDER BY txn_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_balance,
        LAST_VALUE(closing_balance)  OVER (
            PARTITION BY customer_id ORDER BY txn_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_balance
    FROM running_balance
),
flagged AS (
    SELECT
        customer_id, first_balance, last_balance,
        CASE
            WHEN first_balance > 0
             AND (last_balance - first_balance) / first_balance > 0.05
            THEN 1 ELSE 0
        END AS grew_over_5pct
    FROM first_last
)
SELECT
    COUNT(*) AS total_customers,
    SUM(grew_over_5pct) AS customers_grew_over_5pct,
    ROUND(100.0 * SUM(grew_over_5pct) / COUNT(*), 2) AS pct_customers
FROM flagged;