# Case Study #3 - Foodie-Fi
<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png" width="300">

Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

## Case Study Questions

## A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
```sql
SELECT 
    s.customer_id,
    GROUP_CONCAT(
        CONCAT(p.plan_name, ' (', s.start_date, ')')
        ORDER BY s.start_date
        SEPARATOR ' → '
    ) AS journey
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY s.customer_id
ORDER BY s.customer_id
LIMIT 10;
```
**Result**
| customer_id | journey |
|-------------|--------------|
| 1         | trial (2020-08-01) → basic monthly (2020-08-08)         |
| 2         | trial (2020-09-20) → pro annual (2020-09-27)         |
| 3         | trial (2020-01-13) → basic monthly (2020-01-20)         |
| 4         | trial (2020-01-17) → basic monthly (2020-01-24) → churn (2020-04-21)         |
| 5         | trial (2020-08-03) → basic monthly (2020-08-10)         |
| 6         | trial (2020-12-23) → basic monthly (2020-12-30) → churn (2021-02-26)         |
| 7         | trial (2020-02-05) → basic monthly (2020-02-12) → pro monthly (2020-05-22)         |
| 8         | trial (2020-06-11) → basic monthly (2020-06-18) → pro monthly (2020-08-03)        |
| 9         | trial (2020-12-07) → pro annual (2020-12-14)         |
| 10         | trial (2020-09-19) → pro monthly (2020-09-26)         |

## B. Data Analysis Questions
### Question 1
How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT (DISTINCT customer_id) as total_cust
FROM subscriptions;
```
**Result**
| total_cust |
|-------------|
| 1000         |

### Question 2
What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value?
```sql
SELECT 
    MONTHNAME(s.start_date) AS month,
    COUNT(s.customer_id) AS number_of_trial
FROM subscriptions s
JOIN plans p 
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY MONTH(s.start_date), month
ORDER BY MONTH(s.start_date);

```
**Result**
| month |number_of_trial |
|-------------|-------------|
| January         | 88         |
| February         | 68         |
| March         | 94         |
| April         | 81         |
| May         | 88         |
| June         | 79         |
| July         | 89         |
| August         | 88         |
| September         | 87         |
| October         | 79         |
| November         | 75         |
| December         | 84         |

### Question 3
What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name?
```sql
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
```
**Result**
| plan_id |plan_name |total_event |
|-------------|-------------|-------------|
| 1         | basic monthly         |8         |
| 2         | pro monthly         |60         |
| 3         | pro annual         |63         |
| 4         | churn         |71         |

### Question 4
What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
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
```
**Result**
| customer_count |churn_customers |churn_percentage |
|-------------|-------------|-------------|
| 1000         | 307         |30.7         |

### Question 5
How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
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
```
**Result**
| churn_after_trial |percentage |
|-------------|-------------|
| 92         | 9         |

### Question 6
What is the number and percentage of customer plans after their initial free trial?
```sql
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
```
**Result**
| plan_name |customer_count |percentage |
|-------------|-------------|-------------|
| basic monthly         | 546         |54.6         |
| pro annual         | 37         |3.7         |
| pro monthly         | 325         |32.5         |
| churn         | 92         |9.2         |

### Question 7
What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
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
```
**Result**
| plan_id |plan_name |customer_count |percentage |
|-------------|-------------|-------------|
| 0         | trial         |19         |1.9         |
| 1         | basic monthly         |224         |22.4         |
| 2         | pro monthly         |326         |32.6         |
| 3         | pro annual         |195         |19.5         |
| 4         | churn         |236         |23.6         |


### Question 8
How many customers have upgraded to an annual plan in 2020?
```sql
SELECT COUNT(customer_id) AS annual_cust
FROM subscriptions
WHERE start_date <= '2020-12-31'
    AND plan_id = 3;
```
**Result**
| annual_cust |
|-------------|
| 195         |

### Question 9
How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
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
```
**Result**
| avg_days_to_annual |
|-------------|
| 105         |

### Question 10
Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?
```sql
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
```
**Result**
| day_range | customer_count |
|-------------|-------------|
| 0-30 days         | 48         |
| 30-60 days         | 25         |
| 60-90 days         | 33         |
| 90-120 days         | 35         |
| 120-150 days         | 43         |
| 150-180 days         | 35         |
| 180-210 days         | 27         |
| 210-240 days         | 4         |
| 240-270 days         | 5         |
| 270-300 days         | 1         |
| 300-330 days         | 1         |
| 330-360 days         | 1         |

### Question 11
How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
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
```
**Result**
| downgrade_count |
|-------------|
| 0|