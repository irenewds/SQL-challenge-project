USE data_mart;

-- B. Data Exploration

-- 1. What day of the week is used for each week_date value?
SELECT 
    DISTINCT DAYNAME(week_date) AS weekday
FROM clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
WITH RECURSIVE week_number_cte AS (
    SELECT 1 AS week_number
    UNION ALL
    SELECT week_number + 1
    FROM week_number_cte
    WHERE week_number < 52
)

SELECT DISTINCT
    week_no.week_number
FROM week_number_cte AS week_no
LEFT JOIN clean_weekly_sales AS sales
    ON week_no.week_number = sales.week_number
WHERE sales.week_number IS NULL;

-- 3. How many total transactions were there for each year in the dataset?
SELECT
    calendar_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

-- 4. What is the total sales for each region for each month?
SELECT
    region,
    month_number,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region;

-- 5. What is the total count of transactions for each platform?
SELECT
    platform,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH monthly_platform_sales AS (
    SELECT
        calendar_year,
        month_number,
        platform,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, month_number, platform
),
monthly_totals AS (
    SELECT
        calendar_year,
        month_number,
        SUM(total_sales) AS month_total_sales
    FROM monthly_platform_sales
    GROUP BY calendar_year, month_number
)

SELECT
    mps.calendar_year,
    mps.month_number,
    mps.platform,
    mps.total_sales,
    ROUND((mps.total_sales / mt.month_total_sales) * 100, 2) AS sales_percentage
FROM monthly_platform_sales mps
JOIN monthly_totals mt
    ON mps.calendar_year = mt.calendar_year
   AND mps.month_number = mt.month_number
WHERE mps.platform IN ('Retail', 'Shopify')
ORDER BY mps.calendar_year, mps.month_number, mps.platform;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH yearly_demographic_sales AS (
    SELECT
        calendar_year,
        demographic,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, demographic
),
yearly_totals AS (
    SELECT
        calendar_year,
        SUM(total_sales) AS year_total_sales
    FROM yearly_demographic_sales
    GROUP BY calendar_year
)

SELECT
    yds.calendar_year,
    yds.demographic,
    yds.total_sales,
    ROUND((yds.total_sales / yt.year_total_sales) * 100, 2) AS sales_percentage
FROM yearly_demographic_sales yds
JOIN yearly_totals yt
    ON yds.calendar_year = yt.calendar_year
ORDER BY
    yds.calendar_year,
    sales_percentage DESC;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT
    age_band,
    demographic,
    SUM(sales) AS total_retail_sales,
    ROUND(
        (SUM(sales) / (
            SELECT SUM(sales)
            FROM data_mart.clean_weekly_sales
            WHERE platform = 'Retail'
        )) * 100,
        2
    ) AS retail_sales_percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_retail_sales DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
-- The "avg_transaction" column is a pre-aggregated average.
SELECT
    calendar_year,
    platform,
    ROUND(SUM(sales) / SUM(transactions)) AS avg_transaction_size
FROM clean_weekly_sales
WHERE platform IN ('Retail', 'Shopify')
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;