# Case Study #5 - Data Mart
<img src="https://8weeksqlchallenge.com/images/case-study-designs/5.png" width="300">

Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

The key business question he wants you to help him answer are the following:

What was the quantifiable impact of the changes introduced in June 2020?
Which platform, region, segment and customer types were the most impacted by this change?
What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?

## Case Study Questions

## A. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the `data_mart` schema named `clean_weekly_sales`:
- Convert the `week_date` to a `DATE` format
- Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a `month_number` with the calendar month for each `week_date` value as the 3rd column
- Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called `age_band` after the original `segment` column using the following mapping on the number inside the `segment` value
- Add a new `demographic` column using the following mapping for the first letter in the `segment` values
- Ensure all `null` string values with an `"unknown"` string value in the original `segment` column as well as the new `age_band` and `demographic` columns
- Generate a new `avg_transaction` column as the `sales` value divided by `transactions` rounded to 2 decimal places for each record
```sql
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
```
**Result**
| week_date  | week_number | month_number | calendar_year | region | platform | segment | age_band      | demographic | customer_type | transactions | sales    | avg_transaction |
|------------|-------------|--------------|---------------|--------|----------|---------|---------------|-------------|---------------|--------------|----------|-----------------|
| 2020-08-31 | 36          | 8            | 2020          | ASIA   | Retail   | C3      | Retirees      | Couples     | New           | 120631       | 3656163  | 30.31           |
| 2020-08-31 | 36          | 8            | 2020          | ASIA   | Retail   | F1      | Young Adults  | Families    | New           | 31574        | 996575   | 31.56           |
| 2020-08-31 | 36          | 8            | 2020          | USA    | Retail   | unknown | unknown       | unknown     | Guest         | 529151       | 16509610 | 31.20           |
| 2020-08-31 | 36          | 8            | 2020          | EUROPE | Retail   | C1      | Young Adults  | Couples     | New           | 4517         | 141942   | 31.42           |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Retail   | C2      | Middle Aged   | Couples     | New           | 58046        | 1758388  | 30.29           |
| 2020-08-31 | 36          | 8            | 2020          | CANADA | Shopify  | F2      | Middle Aged   | Families    | Existing      | 1336         | 243878   | 182.54          |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Shopify  | F3      | Retirees      | Families    | Existing      | 2514         | 519502   | 206.64          |
| 2020-08-31 | 36          | 8            | 2020          | ASIA   | Shopify  | F1      | Young Adults  | Families    | Existing      | 2158         | 371417   | 172.11          |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Shopify  | F2      | Middle Aged   | Families    | New           | 318          | 49557    | 155.84          |
| 2020-08-31 | 36          | 8            | 2020          | AFRICA | Retail   | C3      | Retirees      | Couples     | New           | 111032       | 3888162  | 35.02           |

## B. Data Exploration
### Question 1
What day of the week is used for each `week_date` value?
```sql
SELECT 
    DISTINCT DAYNAME(week_date) AS weekday
FROM clean_weekly_sales;
```
**Result**
| weekday  |
|------------|
| Monday  |

### Question 2
What range of week numbers are missing from the dataset?
```sql
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
```
**Result**
*Only first ten row shown.*
| week_number  |
|------------|
| 1  |
| 2  |
| 3  |
| 4  |
| 5  |
| 6  |
| 7  |
| 8  |
| 9  |
| 10  |

### Question 3
How many total transactions were there for each year in the dataset?
```sql
SELECT
    calendar_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```
**Result**
| calendar_year  | total_transactions  |
|------------|------------|
| 2018  | 346406460  |
| 2019  | 365639285  |
| 2020  | 375813651  |

### Question 4
What is the total sales for each region for each month?
```sql
SELECT
    region,
    month_number,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region;
```
**Result**
*Only first ten rows shown.*
| region | month_number | total_sales |
|------------|------------|------------|
| AFRICA | 3 | 567767480 |
| AFRICA | 4 | 1911783504 |
| AFRICA | 5 | 1647244738 |
| AFRICA | 6 | 1767559760 |
| AFRICA | 7 | 1960219710 |
| AFRICA | 8 | 1809596890 |
| AFRICA | 9 | 276320987 |
| ASIA | 3 | 529770793 |
| ASIA | 4 | 1804628707 |
| ASIA | 5 | 1526285399 |

### Question 5
What is the total count of transactions for each platform?
```sql
SELECT
    platform,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;
```
**Result**
| platform | total_transactions |
|------------|------------|
| Retail | 1081934227 |
| Shopify | 5925169 |

### Question 6
What is the percentage of sales for Retail vs Shopify for each month?
```sql
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
```
**Result**
*Only first ten rows shown.*
| calendar_year | month_number | platform | total_sales | sales_percentage |
|------------|------------|------------|------------|------------|
| 2018 | 3 | Retail | 525583061 | 97.92 |
| 2018 | 3 | Shopify | 11172391 | 2.08 |
| 2018 | 4 | Retail | 2617369077 | 97.93 |
| 2018 | 4 | Shopify | 55435570 | 2.07 |
| 2018 | 5 | Retail | 2080290488 | 97.73 |
| 2018 | 5 | Shopify | 48365936 | 2.27 |
| 2018 | 6 | Retail | 2061128568 | 97.76 |
| 2018 | 6 | Shopify | 47323635 | 2.24 |
| 2018 | 7 | Retail | 2646368290 | 97.75 |
| 2018 | 7 | Shopify | 60830182 | 2.25 |

### Question 7
What is the percentage of sales by demographic for each year in the dataset?
```sql
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
```
**Result**
| calendar_year | demographic | total_sales | sales_percentage |
|------------|------------|------------|------------|
| 2018 | unknown | 5369434106 | 41.63 |
| 2018 | Families | 4125558033 | 31.99 |
| 2018 | Couples | 3402388688 | 26.38 |
| 2019 | unknown | 5532862221 | 40.25 |
| 2019 | Families | 4463918344 | 32.47 |
| 2019 | Couples | 3749251935 | 27.28 |
| 2020 | unknown | 5436315907 | 38.55 |
| 2020 | Families | 4614338065 | 32.73 |
| 2020 | Couples | 4049566928 | 28.72 |

### Question 8
Which `age_band` and `demographic` values contribute the most to Retail sales?
```sql
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
```
**Result**
| age_band | demographic | total_retail_sales | retail_sales_percentage |
|------------|------------|------------|------------|
| unknown | unknown | 16067285533 | 40.52 |
| Retirees | Families | 6634686916 | 16.73 |
| Retirees | Couples | 6370580014 | 16.07 |
| Middle Aged | Families | 4354091554 | 10.98 |
| Young Adults | Couples | 2602922797 | 6.56 |
| Middle Aged | Couples | 1854160330 | 4.68 |
| Young Adults | Families | 1770889293 | 4.47 |


### Question 9
Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
```sql
SELECT
    calendar_year,
    platform,
    ROUND(SUM(sales) / SUM(transactions)) AS avg_transaction_size
FROM clean_weekly_sales
WHERE platform IN ('Retail', 'Shopify')
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;
```
**Result**
| calendar_year | platform | avg_transaction_size |
|------------|------------|------------|
| 2018 | Retail | 37 |
| 2018 | Shopify | 192 |
| 2019 | Retail | 37 |
| 2019 | Shopify | 183 | 
| 2020 | Retail | 37 | 
| 2020 | Shopify | 179 | 

## C. Data Exploration
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all `week_date` values for `2020-06-15` as the start of the period after the change and the previous `week_date` values would be **before**.

Using this analysis approach - answer the following questions:

### Question 1
What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?

### Question 2
What about the entire 12 weeks before and after?

### Question 3
How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?