USE foodie_fi;


-- B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT (DISTINCT customer_id) as total_cust
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value?
SELECT 
    MONTHNAME(s.start_date) AS month,
    COUNT(s.customer_id) AS number_of_trial
FROM subscriptions s
JOIN plans p 
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY MONTH(s.start_date), month
ORDER BY MONTH(s.start_date);

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
SELECT
    p.plan_id,
    p.plan_name,
    COUNT(s.plan_id) AS total_event
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
    COUNT(DISTINCT s.customer_id) AS customer_count,
    COUNT(DISTINCT CASE WHEN p.plan_name = 'churn' THEN s.customer_id END) AS churn_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN p.plan_name = 'churn' THEN s.customer_id END)
        * 100.0
        / COUNT(DISTINCT s.customer_id),
    1) AS churn_percentage
FROM subscriptions s
JOIN plans p 
    ON s.plan_id = p.plan_id;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH ordered AS (
    SELECT 
        s.customer_id,
        p.plan_name,
        s.start_date,
        LEAD(p.plan_name) OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date
        ) AS next_plan
    FROM subscriptions s
    JOIN plans p 
        ON s.plan_id = p.plan_id
)

SELECT 
    COUNT(*) AS churn_after_trial,
    ROUND(
        COUNT(*) * 100.0 / 
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
    0) AS percentage
FROM ordered
WHERE plan_name = 'trial'
  AND next_plan = 'churn';

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH ordered AS (
    SELECT 
        s.customer_id,
        p.plan_name,
        s.start_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date
        ) AS rn
    FROM subscriptions s
    JOIN plans p 
        ON s.plan_id = p.plan_id
)

SELECT 
    plan_name,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
    1) AS percentage
FROM ordered
WHERE rn = 2
GROUP BY plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH latest AS (
    SELECT 
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date DESC
        ) AS rn
    FROM subscriptions s
    JOIN plans p 
        ON s.plan_id = p.plan_id
    WHERE s.start_date <= '2020-12-31'
)

SELECT 
    plan_id,
    plan_name,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
    1) AS percentage
FROM latest
WHERE rn = 1
GROUP BY plan_id, plan_name
ORDER BY plan_id;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(customer_id) AS annual_cust
FROM subscriptions
WHERE start_date <= '2020-12-31'
    AND plan_id = 3;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH dates AS (
    SELECT 
        s.customer_id,
        MIN(CASE WHEN p.plan_name = 'trial' THEN s.start_date END) AS trial_date,
        MIN(CASE WHEN p.plan_name = 'pro annual' THEN s.start_date END) AS annual_date
    FROM subscriptions s
    JOIN plans p 
        ON s.plan_id = p.plan_id
    GROUP BY s.customer_id
)

SELECT 
    ROUND(AVG(DATEDIFF(annual_date, trial_date)), 0) AS avg_days_to_annual
FROM dates
WHERE annual_date IS NOT NULL;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH base AS (
    SELECT 
        DATEDIFF(
            MIN(CASE WHEN p.plan_name = 'pro annual' THEN s.start_date END),
            MIN(CASE WHEN p.plan_name = 'trial' THEN s.start_date END)
        ) AS days_to_annual
    FROM subscriptions s
    JOIN plans p 
        ON s.plan_id = p.plan_id
    GROUP BY s.customer_id
    HAVING days_to_annual IS NOT NULL
)

SELECT 
    CONCAT(bucket * 30, '-', bucket * 30 + 30, ' days') AS day_range,
    COUNT(*) AS customer_count
FROM (
    SELECT FLOOR(days_to_annual / 30) AS bucket
    FROM base
) t
GROUP BY bucket
ORDER BY bucket;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH ordered AS (
    SELECT 
        s.customer_id,
        p.plan_name,
        s.start_date,
        LEAD(p.plan_name) OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date
        ) AS next_plan,
        LEAD(s.start_date) OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date
        ) AS next_date
    FROM subscriptions s
    JOIN plans p 
        ON s.plan_id = p.plan_id
)

SELECT 
    COUNT(DISTINCT customer_id) AS downgrade_count
FROM ordered
WHERE plan_name = 'pro monthly'
  AND next_plan = 'basic monthly'
  AND YEAR(next_date) = 2020;