USE data_bank;

SELECT *
FROM regions;
SELECT *
FROM customer_nodes
LIMIT 10;
SELECT *
FROM customer_transactions
LIMIT 10;


-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_node
FROM customer_nodes;

-- 2. What is the number of nodes per region?
SELECT
    r.region_name AS region,
    COUNT(DISTINCT cn.node_id) AS number_of_nodes
FROM customer_nodes cn
JOIN regions r
    ON cn.region_id = r.region_id
GROUP BY region;

-- 3. How many customers are allocated to each region?
SELECT
    r.region_name AS region,
    COUNT(DISTINCT cn.customer_id) AS total_customers
FROM customer_nodes cn
JOIN regions r
    ON cn.region_id = r.region_id
GROUP BY region;

-- 4. How many days on average are customers reallocated to a different node?

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?