# Case Study #4 - Data Bank
<img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" width="300">

There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!

Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Case Study Questions

## A. Customer Nodes Exploration
### Question 1
How many unique nodes are there on the Data Bank system?
```sql
SELECT COUNT(DISTINCT node_id) AS unique_node
FROM customer_nodes;
```
**Result**

### Question 2
What is the number of nodes per region?
```sql
SELECT
    r.region_name AS region,
    COUNT(DISTINCT cn.node_id) AS number_of_nodes
FROM customer_nodes cn
JOIN regions r
    ON cn.region_id = r.region_id
GROUP BY region;
```
**Result**

### Question 3
How many customers are allocated to each region?
```sql
SELECT
    r.region_name AS region,
    COUNT(DISTINCT cn.customer_id) AS total_customers
FROM customer_nodes cn
JOIN regions r
    ON cn.region_id = r.region_id
GROUP BY region;
```
**Result**

### Question 4
How many days on average are customers reallocated to a different node?
```sql
WITH node_durations AS (
    SELECT
        customer_id,
        node_id,
        region_id,
        start_date,
        end_date,
        DATEDIFF(end_date, start_date) AS days_in_node
    FROM customer_nodes
    WHERE end_date <> '9999-12-31'
)

SELECT
    ROUND(AVG(days_in_node)) AS avg_reallocation_days
FROM node_durations;
```
**Result**

### Question 5
What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
```
**Result**

## B. Customer Transactions
### Question 1
What is the unique count and total amount for each transaction type?
```sql
SELECT
    txn_type,
    COUNT(*) AS unique_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;
```
**Result**

### Question 2
What is the average total historical deposit counts and amounts for all customers?
```sql
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
```
**Result**

### Question 3
For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
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
```
**Result**

### Question 4
What is the closing balance for each customer at the end of the month?
```sql
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
```
**Result**

### Question 5
What is the percentage of customers who increase their closing balance by more than 5%?
```sql
```
**Result**