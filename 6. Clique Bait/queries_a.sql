USE clique_bait

-- A. Digital Analysis
-- Using the available datasets - answer the following questions using a single query for each one:

-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) as user_count
FROM users;

-- 2. How many cookies does each user have on average?
WITH cookies AS (
SELECT
    user_id,
    COUNT(DISTINCT cookie_id) AS cookies_count
FROM users
GROUP BY user_id
)

SELECT
    AVG(cookies_count) AS average_cookies
FROM cookies;

-- 3. What is the unique number of visits by all users per month?
SELECT 
  MONTH(event_time) AS month,
  COUNT(DISTINCT visit_id) AS unique_visits
FROM events
GROUP BY month
ORDER BY month;

-- 4. What is the number of events for each event type?
SELECT
    e.event_type AS event_type,
    ed.event_name AS event_name,
    COUNT(*) AS number_of_events
FROM events e
INNER JOIN event_identifier ed
ON e.event_type = ed.event_type
GROUP BY 
    event_type,
    event_name;

-- 5. What is the percentage of visits which have a purchase event?
SELECT 
  ROUND(
    100 * COUNT(DISTINCT CASE WHEN event_type = 3 THEN visit_id END)
    / COUNT(DISTINCT visit_id),
    2
  ) AS purchase_percentage
FROM events;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH checkout AS (
  SELECT 
    visit_id,
    MAX(CASE WHEN page_id = 12 THEN 1 ELSE 0 END) AS viewed_checkout,
    MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS has_purchase
  FROM events
  GROUP BY visit_id
)

SELECT 
  ROUND(
    100 * SUM(CASE WHEN viewed_checkout = 1 AND has_purchase = 0 THEN 1 ELSE 0 END)
    / SUM(viewed_checkout),
    2
  ) AS checkout_no_purchase_percentage
FROM checkout;

-- 7. What are the top 3 pages by number of views?
SELECT
    e.page_id AS page_id,
    p.page_name AS page_name,
    COUNT(*) AS top_views_count
FROM events e
JOIN page_hierarchy p
    ON e.page_id = p.page_id
WHERE event_type = 1
GROUP BY 
    page_id,
    page_name
ORDER BY top_views_count DESC
LIMIT 3;

-- 8. What is the number of views and cart adds for each product category?
SELECT
  ph.product_category,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) as page_views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) as cart_adds
FROM events e
JOIN page_hierarchy ph
  ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category;

-- 9. What are the top 3 products by purchases?
