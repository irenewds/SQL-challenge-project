USE data_bank;

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

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH reallocation_days AS (
    SELECT
        cn.region_id,
        r.region_name,
        DATEDIFF(cn.end_date, cn.start_date) AS days_reallocated
    FROM customer_nodes cn
    JOIN regions r ON r.region_id = cn.region_id
    WHERE cn.end_date != '9999-12-31'
),
ranked AS (
    SELECT
        region_id, region_name, days_reallocated,
        ROW_NUMBER() OVER (
            PARTITION BY region_id ORDER BY days_reallocated
        ) AS row_num,
        COUNT(*) OVER (PARTITION BY region_id) AS total_rows
    FROM reallocation_days
),
percentiles AS (
    SELECT *,
        CEIL(0.50 * total_rows) AS p50_idx,
        CEIL(0.80 * total_rows) AS p80_idx,
        CEIL(0.95 * total_rows) AS p95_idx
    FROM ranked
)
SELECT
    region_name,
    MAX(CASE WHEN row_num = p50_idx THEN days_reallocated END) AS median_days,
    MAX(CASE WHEN row_num = p80_idx THEN days_reallocated END) AS p80_days,
    MAX(CASE WHEN row_num = p95_idx THEN days_reallocated END) AS p95_days
FROM percentiles
GROUP BY region_id, region_name
ORDER BY region_name;