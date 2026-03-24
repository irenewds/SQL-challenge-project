USE dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    sales.customer_id,
    SUM(menu.price) AS total_sales
FROM sales
INNER JOIN menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS total_days
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_item AS (
SELECT
    customer_id,
    product_id,
    DENSE_RANK() OVER (
      PARTITION BY customer_id
      ORDER BY order_date) AS ranked
FROM sales
)

SELECT
    f.customer_id,
    m.product_name
FROM first_item f
INNER JOIN menu m
    ON f.product_id = m.product_id
WHERE f.ranked = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    m.product_name,
    count(s.product_id) AS most_purchased
FROM sales s
INNER JOIN menu m
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH most_popular AS (
  SELECT 
    sales.customer_id, 
    menu.product_name, 
    COUNT(menu.product_id) AS order_count,
    DENSE_RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY COUNT(sales.customer_id) DESC) AS ranked
  FROM menu
  INNER JOIN sales
    ON menu.product_id = sales.product_id
  GROUP BY sales.customer_id, menu.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE ranked = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchase AS (
SELECT
    sales.customer_id,
    sales.order_date,
    members.join_date,
    sales.product_id,
    ROW_NUMBER() OVER (
        PARTITION BY sales.customer_id
        ORDER BY sales.order_date) AS rank_num,
    menu.product_name
FROM sales
INNER JOIN members
    ON sales.customer_id = members.customer_id
INNER JOIN menu
    ON sales.product_id = menu.product_id
WHERE members.join_date <= sales.order_date
)

SELECT
    customer_id,
    product_name
FROM first_purchase
WHERE rank_num = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH last_purchase AS (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        RANK() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.order_date DESC) AS ranked
    FROM sales s
    INNER JOIN members mm
        ON s.customer_id = mm.customer_id
    INNER JOIN menu m
        ON s.product_id = m.product_id
    WHERE mm.join_date > s.order_date
)

SELECT
    customer_id,
    order_date,
    product_name
FROM last_purchase
WHERE ranked = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    sales.customer_id,
    COUNT(sales.product_id) AS total_items,
    SUM(menu.price)
FROM sales
INNER JOIN menu
    ON sales.product_id = menu.product_id
INNER JOIN members
    ON sales.customer_id = members.customer_id
    AND members.join_date > sales.order_date
GROUP BY sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_cte AS (
SELECT 
    product_id,
    CASE
        WHEN product_id = 1 THEN price * 20
        ELSE price * 10 END AS points
FROM menu
)

SELECT
    sales.customer_id,
    SUM(points_cte.points) AS total_points
FROM sales
INNER JOIN points_cte
    ON sales.product_id = points_cte.product_id
GROUP BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH jan_data AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        mem.join_date
    FROM sales s
    JOIN menu m
        ON s.product_id = m.product_id
    LEFT JOIN members mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date <= '2021-01-31'
),
points_cte AS (
    SELECT *,
        CASE
            WHEN join_date IS NOT NULL
             AND order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY)
                THEN price * 20
            WHEN product_name = 'sushi'
                THEN price * 20
            ELSE price * 10
        END AS points
    FROM jan_data
)

SELECT
    customer_id,
    SUM(points) AS total_points
FROM points_cte
WHERE customer_id IN ('A', 'B')
GROUP BY customer_id
ORDER BY customer_id;


-- BONUS QUESTIONS

-- Join All The Things
-- Recreate a table output (Member Status)
SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN mm.join_date > s.order_date THEN 'N'
        WHEN mm.join_date <= s.order_date THEN 'Y'
        ELSE 'N' END AS member
FROM sales s
LEFT JOIN members mm
    ON s.customer_id = mm.customer_id
INNER JOIN menu m
    ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date;

-- Join All The Things
-- Recreate a table output (Member and Rank)
WITH member_cte AS (
SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN mm.join_date > s.order_date THEN 'N'
        WHEN mm.join_date <= s.order_date THEN 'Y'
        ELSE 'N' END AS member
FROM sales s
LEFT JOIN members mm
    ON s.customer_id = mm.customer_id
INNER JOIN menu m
    ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date
)

SELECT
    *,
    CASE WHEN member = 'N' THEN NULL
    ELSE RANK () OVER (
        PARTITION BY customer_id, member
        ORDER BY order_date) END AS ranking
FROM member_cte;