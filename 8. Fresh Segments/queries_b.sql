USE fresh_segments;

SELECT *
FROM interest_map
LIMIT 10;
SELECT *
FROM interest_metrics
LIMIT 10;

-- B. Interest Analysis

-- 1. Which interests have been present in all month_year dates in our dataset?
WITH total_months AS (
    SELECT COUNT(DISTINCT month_year) AS month_count
    FROM fresh_segments.interest_metrics
)

SELECT
    im.interest_id,
    mp.interest_name,
    COUNT(DISTINCT im.month_year) AS months_present
FROM fresh_segments.interest_metrics im
INNER JOIN fresh_segments.interest_map mp
    ON im.interest_id = mp.id
WHERE im.month_year IS NOT NULL
GROUP BY im.interest_id, mp.interest_name
HAVING COUNT(DISTINCT im.month_year) = (SELECT month_count FROM total_months)
ORDER BY im.interest_id;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

-- 5. After removing these interests - how many unique interests are there for each month?