USE pizza_runner;

-- C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?
-- Making temporary table
CREATE TEMPORARY TABLE pizza_recipes_toppings AS
SELECT 
    p.pizza_id,
    TRIM(jt.topping_id) AS topping_id,
    pt.topping_name
FROM pizza_recipes p
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(p.toppings, ',', '","'), '"]'),
    '$[*]' COLUMNS (
        topping_id VARCHAR(10) PATH '$'
    )
) AS jt
JOIN pizza_toppings pt
    ON TRIM(jt.topping_id) = pt.topping_id;

SELECT *
FROM pizza_recipes_toppings
ORDER BY pizza_id, topping_id;

-- 2. What was the most commonly added extra?
WITH extras_split AS (
    SELECT
        c.order_id,
        CAST(TRIM(jt.extra_id) AS UNSIGNED) AS topping_id
    FROM customer_orders c
    JOIN JSON_TABLE(
        CONCAT('["', REPLACE(c.extras, ',', '","'), '"]'),
        '$[*]' COLUMNS (
            extra_id VARCHAR(10) PATH '$'
        )
    ) AS jt
    WHERE c.extras != ''
)

SELECT
    pt.topping_name,
    COUNT(*) AS total_added
FROM extras_split e
JOIN pizza_toppings pt
    ON e.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_added DESC
LIMIT 1;

-- 3. What was the most common exclusion?
WITH exclusions_split AS (
    SELECT
        c.order_id,
        CAST(TRIM(jt.exclusion_id) AS UNSIGNED) AS topping_id
    FROM customer_orders c
    JOIN JSON_TABLE(
        CONCAT('["', REPLACE(c.exclusions, ',', '","'), '"]'),
        '$[*]' COLUMNS (
            exclusion_id VARCHAR(10) PATH '$'
        )
    ) AS jt
    WHERE c.exclusions != ''
)

SELECT
    pt.topping_name,
    COUNT(*) AS total_excluded
FROM exclusions_split e
JOIN pizza_toppings pt
    ON e.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_excluded DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT
    c.order_id,
    CONCAT(
        p.pizza_name,
        IF(
            c.exclusions IS NOT NULL AND c.exclusions NOT IN ('', 'null'),
            CONCAT(
                ' - Exclude ',
                (
                    SELECT GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ')
                    FROM JSON_TABLE(
                        CONCAT('["', REPLACE(c.exclusions, ',', '","'), '"]'),
                        '$[*]' COLUMNS (id VARCHAR(10) PATH '$')
                    ) jt
                    JOIN pizza_toppings pt
                        ON pt.topping_id = CAST(jt.id AS UNSIGNED)
                )
            ),
            ''
        ),
        IF(
            c.extras IS NOT NULL AND c.extras NOT IN ('', 'null'),
            CONCAT(
                ' - Extra ',

                (
                    SELECT GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ')
                    FROM JSON_TABLE(
                        CONCAT('["', REPLACE(c.extras, ',', '","'), '"]'),
                        '$[*]' COLUMNS (id VARCHAR(10) PATH '$')
                    ) jt
                    JOIN pizza_toppings pt
                        ON pt.topping_id = CAST(jt.id AS UNSIGNED)
                )
            ),
            ''
        )
    ) AS order_item
FROM customer_orders c
JOIN pizza_names p
    ON c.pizza_id = p.pizza_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?