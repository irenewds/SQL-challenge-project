USE pizza_runner;

-- Table 2: customer_orders
SELECT *
from customer_orders;

UPDATE customer_orders
SET exclusions = ''
WHERE exclusions IS NULL
   OR exclusions = 'null';

UPDATE customer_orders
SET extras = ''
WHERE extras IS NULL
   OR extras = 'null';

-- Table 3: runner_orders
SELECT *
FROM runner_orders;

UPDATE runner_orders
SET 
    pickup_time = CASE 
              WHEN pickup_time IS NULL OR pickup_time = 'null' THEN '' 
              ELSE pickup_time 
           END,
    distance = CASE 
              WHEN distance IS NULL OR distance = 'null' THEN '' 
              ELSE distance 
           END,
    duration = CASE 
              WHEN duration IS NULL OR duration = 'null' THEN '' 
              ELSE duration 
           END,
    cancellation = CASE 
              WHEN cancellation IS NULL OR cancellation = 'null' THEN '' 
              ELSE cancellation 
           END;

UPDATE runner_orders
SET duration = CASE
    WHEN duration IS NULL OR duration = '' THEN NULL
    ELSE REGEXP_REPLACE(duration, '[^0-9]', '')
END;

ALTER TABLE runner_orders
MODIFY duration INT;