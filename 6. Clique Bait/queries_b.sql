USE clique_bait;

SELECT *
FROM event_identifier;
SELECT *
FROM campaign_identifier;
SELECT *
FROM page_hierarchy;
SELECT *
FROM users
LIMIT 10;
SELECT *
FROM events
LIMIT 10;

-- B. Product Funnel Analysis

-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?


-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
-- Use your 2 new output tables - answer the following questions:
-- 1. Which product had the most views, cart adds and purchases?
-- 2. Which product was most likely to be abandoned?
-- 3. Which product had the highest view to purchase percentage?
-- 4. What is the average conversion rate from view to cart add?
-- 5. What is the average conversion rate from cart add to purchase?