USE balanced_tree;

SELECT *
FROM product_details;
SELECT *
FROM sales;

-- C. Product Analysis

-- 1. What are the top 3 products by total revenue before discount?
SELECT
    pd.product_name,
    SUM(s.qty * s.price) AS total_revenue
FROM sales s
JOIN product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT
    pd.segment_name AS segment,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    SUM(s.price * s.qty * s.discount)/100 AS total_discount
FROM sales s
JOIN product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.segment_name;

-- 3. What is the top selling product for each segment?
WITH product_sales AS (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty) AS total_quantity_sold,
        RANK() OVER (
            PARTITION BY pd.segment_name
            ORDER BY SUM(s.qty) DESC
        ) AS ranking
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
)

SELECT
    segment_name,
    product_name AS top_selling_product,
    total_quantity_sold
FROM product_sales
WHERE ranking = 1;

-- 4. What is the total quantity, revenue and discount for each category?
SELECT
    pd.category_name AS category,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    SUM(s.price * s.qty * s.discount)/100 AS total_discount
FROM sales s
JOIN product_details pd
    ON s.prod_id = pd.product_id
GROUP BY category;

-- 5. What is the top selling product for each category?
WITH product_sales AS (
    SELECT
        pd.category_name,
        pd.product_name,
        SUM(s.qty) AS total_quantity_sold,
        RANK() OVER (
            PARTITION BY pd.category_name
            ORDER BY SUM(s.qty) DESC
        ) AS ranking
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.product_name
)

SELECT
    category_name,
    product_name AS top_selling_product,
    total_quantity_sold
FROM product_sales
WHERE ranking = 1;

-- 6. What is the percentage split of revenue by product for each segment?
WITH product_revenue AS (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * s.price) AS product_revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
),
segment_totals AS (
    SELECT
        segment_name,
        SUM(product_revenue) AS segment_revenue
    FROM product_revenue
    GROUP BY segment_name
)

SELECT
    pr.segment_name,
    pr.product_name,
    pr.product_revenue,
    ROUND((pr.product_revenue / st.segment_revenue) * 100, 2) AS revenue_percentage
FROM product_revenue pr
JOIN segment_totals st
    ON pr.segment_name = st.segment_name
ORDER BY pr.segment_name, revenue_percentage DESC;

-- 7. What is the percentage split of revenue by segment for each category?
WITH segment_revenue AS (
    SELECT
        pd.category_name,
        pd.segment_name,
        SUM(s.qty * s.price) AS segment_revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.segment_name
),
category_totals AS (
    SELECT
        category_name,
        SUM(segment_revenue) AS category_revenue
    FROM segment_revenue
    GROUP BY category_name
)

SELECT
    sr.category_name,
    sr.segment_name,
    sr.segment_revenue,
    ROUND((sr.segment_revenue / ct.category_revenue) * 100, 2) AS revenue_percentage
FROM segment_revenue sr
JOIN category_totals ct
    ON sr.category_name = ct.category_name
ORDER BY sr.category_name, revenue_percentage DESC;

-- 8. What is the percentage split of total revenue by category?
WITH category_revenue AS (
    SELECT
        pd.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM sales s
    JOIN product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name
),
total_revenue AS (
    SELECT SUM(revenue) AS overall_revenue
    FROM category_revenue cr
)

SELECT
    cr.category_name,
    cr.revenue,
    ROUND((cr.revenue / tr.overall_revenue) * 100, 2) AS revenue_percentage
FROM category_revenue cr
JOIN total_revenue tr
ORDER BY revenue_percentage DESC;

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH total_transactions AS (
    SELECT COUNT(DISTINCT txn_id) AS total_txns
    FROM balanced_tree.sales
),
product_transactions AS (
    SELECT
        pd.product_name,
        COUNT(DISTINCT s.txn_id) AS product_txns
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    WHERE s.qty > 0
    GROUP BY pd.product_name
)

SELECT
    pt.product_name,
    pt.product_txns,
    tt.total_txns,
    ROUND((pt.product_txns / tt.total_txns) * 100, 2) AS penetration_percentage
FROM product_transactions pt
JOIN total_transactions tt
ORDER BY penetration_percentage DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?