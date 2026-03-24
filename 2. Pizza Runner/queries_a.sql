USE pizza_runner;

-- A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT COUNT(pizza_id) as pizza_order_count
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS order_count
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT 
    runner_id,
    COUNT(order_id) as order_count
FROM runner_orders
WHERE cancellation = ''
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT 
    p.pizza_name,
    COUNT(r.order_id)
FROM runner_orders r
INNER JOIN customer_orders c
    ON r.order_id = c.order_id
INNER JOIN pizza_names p
    ON c.pizza_id = p.pizza_id
WHERE r.cancellation = ''
GROUP BY p.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    c.customer_id,
    p.pizza_name,
    COUNT(c.order_id) as order_count
FROM customer_orders c
INNER JOIN pizza_names p
    ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT
    r.order_id,
    COUNT(c.pizza_id) AS pizza_delivered
FROM runner_orders r
INNER JOIN customer_orders c
    ON r.order_id = c.order_id
WHERE r.cancellation = ''
GROUP BY r.order_id
ORDER BY pizza_delivered DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  c.customer_id,
  SUM(
    CASE WHEN c.exclusions <> '' OR c.extras <> '' THEN 1
    ELSE 0
    END) AS at_least_1_change,
  SUM(
    CASE WHEN c.exclusions = '' AND c.extras = '' THEN 1 
    ELSE 0
    END) AS no_change
FROM customer_orders AS c
JOIN runner_orders AS r
  ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(c.order_id) AS total_pizza
FROM customer_orders c
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
WHERE
    r.cancellation = ''
    AND c.exclusions != ''
    AND c.extras != '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
    HOUR(order_time) AS hour_of_day,
    COUNT(order_id) AS total_pizza
FROM customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- 10. What was the volume of orders for each day of the week?
SELECT
    DAYNAME(order_time) AS day_of_week,
    COUNT(order_id) AS total_pizza
FROM customer_orders
GROUP BY day_of_week
ORDER BY day_of_week;