USE data_mart;

-- A. Data Cleansing Steps

-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
-- Convert the week_date to a DATE format
-- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- Add a month_number with the calendar month for each week_date value as the 3rd column
-- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
-- Add a new demographic column using the following mapping for the first letter in the segment values:
-- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
CREATE TABLE data_mart.clean_weekly_sales AS
SELECT
    STR_TO_DATE(week_date, '%d/%m/%y') AS week_date,
    WEEK(STR_TO_DATE(week_date, '%d/%m/%y'), 3) AS week_number,
    MONTH(STR_TO_DATE(week_date, '%d/%m/%y')) AS month_number,
    YEAR(STR_TO_DATE(week_date, '%d/%m/%y')) AS calendar_year,
    region,
    platform,

    CASE
        WHEN segment IS NULL
          OR segment = ''
          OR LOWER(segment) = 'null'
        THEN 'unknown'
        ELSE segment
    END AS segment,

    CASE
        WHEN segment IS NULL
          OR segment = ''
          OR LOWER(segment) = 'null'
        THEN 'unknown'
        WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
        WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
        WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
        ELSE 'unknown'
    END AS age_band,

    CASE
        WHEN segment IS NULL
          OR segment = ''
          OR LOWER(segment) = 'null'
        THEN 'unknown'
        WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
        WHEN LEFT(segment, 1) = 'F' THEN 'Families'
        ELSE 'unknown'
    END AS demographic,

    customer_type,
    transactions,
    sales,
    ROUND(sales / transactions, 2) AS avg_transaction
FROM data_mart.weekly_sales;

SELECT *
FROM clean_weekly_sales
LIMIT 10;