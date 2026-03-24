USE pizza_runner;

-- B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
  FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) + 1 AS week_number,
  COUNT(*) AS runner_count
FROM runners
GROUP BY week_number
ORDER BY week_number;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
    r.runner_id,
    AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time)) AS avg_arrival_time
FROM runner_orders r
INNER JOIN customer_orders c
ON r.order_id = c.order_id
GROUP BY r.runner_id
ORDER BY r.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pizza_count AS (
    SELECT
        c.order_id,
        COUNT(c.order_id) as pizza_order,
        c.order_time,
        r.pickup_time,
        TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time
    FROM customer_orders c
    INNER JOIN runner_orders r
        ON c.order_id = r.order_id
    WHERE r.cancellation = ''
    GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT
    pizza_order,
    AVG(prep_time) AS avg_prep_time
FROM pizza_count
GROUP BY pizza_order;

-- 4. What was the average distance travelled for each customer?
SELECT
    c.customer_id,
    AVG(r.distance) AS avg_distance
FROM customer_orders c
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
    AND r.cancellation = ''
GROUP BY c.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
    MIN(duration) AS min_delivery_time,
    MAX(duration) AS max_delivery_time,
    MAX(duration) - MIN(duration) AS dif_delivery_time
FROM runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
    runner_id,
    order_id, 
    round(AVG(distance*60/duration),2) as avg_speed 
FROM runner_orders
where cancellation = ""
GROUP BY runner_id, order_id
ORDER BY runner_id, order_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT
    runner_id,
    ROUND(100 * SUM(
        CASE WHEN cancellation = '' THEN 1 
        ELSE 0 END) / COUNT(*), 2) AS success_percentage
FROM runner_orders
GROUP BY runner_id;