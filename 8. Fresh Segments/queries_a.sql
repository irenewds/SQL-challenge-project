USE fresh_segments;

-- A. Data Exploration and Cleansing

-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month.
-- Add a new DATE column
ALTER TABLE fresh_segments.interest_metrics
ADD COLUMN month_start DATE;

UPDATE fresh_segments.interest_metrics
SET month_start = STR_TO_DATE(CONCAT('01-', month_year), '%d-%m-%Y');

-- Drop old column
ALTER TABLE fresh_segments.interest_metrics
DROP COLUMN month_year;

--  Rename new column
ALTER TABLE fresh_segments.interest_metrics
CHANGE COLUMN month_start month_year DATE;

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT
    month_year,
    COUNT(*) AS record_count
FROM interest_metrics
GROUP BY month_year
ORDER BY
    month_year IS NOT NULL,
    month_year;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics?
-- First, let's check how many values each column has.
SELECT
    SUM(CASE WHEN month_year IS NULL THEN 1 ELSE 0 END) AS month_year_nulls,
    SUM(CASE WHEN interest_id IS NULL THEN 1 ELSE 0 END) AS interest_id_nulls,
    SUM(CASE WHEN composition IS NULL THEN 1 ELSE 0 END) AS composition_nulls,
    SUM(CASE WHEN index_value IS NULL THEN 1 ELSE 0 END) AS index_value_nulls,
    SUM(CASE WHEN ranking IS NULL THEN 1 ELSE 0 END) AS rank_nulls,
    SUM(CASE WHEN percentile_ranking IS NULL THEN 1 ELSE 0 END) AS percentile_rank_nulls
FROM interest_metrics;

-- Then, let's compare the amount to the entire dataset.
SELECT
    COUNT(*) AS total_rows,
    SUM(month_year IS NULL OR interest_id IS NULL) AS rows_with_nulls,
    ROUND(
        (SUM(month_year IS NULL OR interest_id IS NULL) / COUNT(*)) * 100,
        2
    ) AS null_row_percentage
FROM interest_metrics;

-- Since the total is less than 10%, hence I would suggest to drop the null value rows.
DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL
   OR interest_id IS NULL;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT
    (
        SELECT COUNT(DISTINCT met.interest_id)
        FROM interest_metrics met
        LEFT JOIN interest_map map
            ON met.interest_id = map.id
        WHERE met.interest_id IS NOT NULL
          AND map.id IS NULL
    ) AS metrics_not_in_map,

    (
        SELECT COUNT(DISTINCT map.id)
        FROM interest_map map
        LEFT JOIN interest_metrics met
            ON map.id = met.interest_id
        WHERE met.interest_id IS NULL
    ) AS map_not_in_metrics;

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT 
    map.id, 
    map.interest_name, 
    COUNT(met.interest_id) AS record_count
FROM interest_map map
JOIN interest_metrics met
    ON map.id = met.interest_id
GROUP BY map.id, map.interest_name
ORDER BY record_count DESC
LIMIT 10;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
-- We are gonna use 'INNER JOIN' with the base table being interest_metrics
SELECT
    met.*,
    map.interest_name,
    map.interest_summary,
    map.created_at,
    map.last_modified
FROM fresh_segments.interest_metrics met
INNER JOIN fresh_segments.interest_map map
    ON met.interest_id = map.id
WHERE met.interest_id = 21246;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT
    COUNT(*) AS invalid_records
FROM fresh_segments.interest_map AS map
INNER JOIN fresh_segments.interest_metrics AS met
    ON map.id = met.interest_id
WHERE met.month_year < CAST(map.created_at AS DATE);