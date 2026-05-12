USE data_mart;

SELECT *
FROM clean_weekly_sales
LIMIT 10;

-- C. Before & After Analysis

-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

-- Using this analysis approach - answer the following questions:
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
WITH baseline AS (
    SELECT DATE('2020-06-15') AS change_date
),
sales_periods AS (
    SELECT
        CASE
            WHEN week_date >= DATE_SUB((SELECT change_date FROM baseline), INTERVAL 4 WEEK)
             AND week_date < (SELECT change_date FROM baseline)
                THEN 'Before'
            WHEN week_date >= (SELECT change_date FROM baseline)
             AND week_date < DATE_ADD((SELECT change_date FROM baseline), INTERVAL 4 WEEK)
                THEN 'After'
        END AS period,
        sales
    FROM data_mart.clean_weekly_sales
    WHERE week_date >= DATE_SUB((SELECT change_date FROM baseline), INTERVAL 4 WEEK)
      AND week_date < DATE_ADD((SELECT change_date FROM baseline), INTERVAL 4 WEEK)
)

SELECT
    before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_difference,
    ROUND(((after_sales - before_sales) / before_sales) * 100, 2) AS percentage_change
FROM (
    SELECT
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales
    FROM sales_periods
) summary;

-- 2. What about the entire 12 weeks before and after?
WITH baseline AS (
    SELECT DATE('2020-06-15') AS change_date
),
sales_periods AS (
    SELECT
        CASE
            WHEN week_date >= DATE_SUB((SELECT change_date FROM baseline), INTERVAL 12 WEEK)
             AND week_date < (SELECT change_date FROM baseline)
                THEN 'Before'
            WHEN week_date >= (SELECT change_date FROM baseline)
             AND week_date < DATE_ADD((SELECT change_date FROM baseline), INTERVAL 12 WEEK)
                THEN 'After'
        END AS period,
        sales
    FROM data_mart.clean_weekly_sales
    WHERE week_date >= DATE_SUB((SELECT change_date FROM baseline), INTERVAL 12 WEEK)
      AND week_date < DATE_ADD((SELECT change_date FROM baseline), INTERVAL 12 WEEK)
)

SELECT
    before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_difference,
    ROUND(((after_sales - before_sales) / before_sales) * 100, 2) AS percentage_change
FROM (
    SELECT
        SUM(CASE WHEN period = 'Before' THEN sales ELSE 0 END) AS before_sales,
        SUM(CASE WHEN period = 'After' THEN sales ELSE 0 END) AS after_sales
    FROM sales_periods
) summary;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
