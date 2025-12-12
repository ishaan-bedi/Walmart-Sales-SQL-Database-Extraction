-- 1. Date Range Covered
SELECT MIN(date) AS start_date, MAX(date) AS end_date FROM sales;

-- 2. Total Weekly Sales by Store
SELECT s.Store, st.Category, st.Size, ROUND(SUM(s.Weekly_Sales),2) AS total_sales
FROM sales s
JOIN stores st ON s.Store = st.Store
GROUP BY s.Store, st.Category, st.Size
ORDER BY total_sales DESC;

-- 3. Total Sales by Category and Year
SELECT 
    st.Category,
    YEAR(s.Date) AS year,
    SUM(s.Weekly_Sales) AS total_sales
FROM sales s
JOIN stores st ON s.Store = st.Store
GROUP BY st.Category, year
ORDER BY total_sales DESC;

-- 4. Master Sales Table Creation
CREATE TABLE master_sales_data AS
SELECT 
    s.Store,
    s.Dept,
    s.Date,
    s.Weekly_Sales,
    s.IsHoliday,
    st.Category,
    st.Size,
    f.Temperature,
    f.Fuel_Price,
    f.CPI,
    f.Unemployment
FROM sales s
LEFT JOIN stores st 
    ON s.Store = st.Store
LEFT JOIN features f 
    ON s.Store = f.Store 
   AND s.Date = f.Date;

-- Aggregated Sales by Store and Date (Version 2) (useful for training data models)
SELECT 
    s.Store,
    s.Date,
    SUM(s.Weekly_Sales) AS total_sales,
    MAX(s.IsHoliday) AS is_holiday, -- holiday flag for that week
    st.Category,
    st.Size,
    AVG(f.Temperature) AS avg_temp,
    AVG(f.Fuel_Price) AS avg_fuel_price,
    AVG(f.CPI) AS avg_cpi,
    AVG(f.Unemployment) AS avg_unemployment
FROM sales s
LEFT JOIN stores st 
    ON s.Store = st.Store
LEFT JOIN features f 
    ON s.Store = f.Store 
   AND s.Date = f.Date
GROUP BY s.Store, s.Date, st.Category, st.Size
ORDER BY s.Store, s.Date;


-- 6. Average Weekly Sales per Department by Year
SELECT Dept, ROUND(AVG(Weekly_Sales), 2) AS avg_weekly_sales,
YEAR(Date) AS sales_year
FROM sales
GROUP BY Dept, sales_year
ORDER BY Dept ASC;

-- 7. Temperature and Fuel Price Statistics by Month and Store
SELECT
  f.Store,
  YEAR(f.Date) AS year,
  MONTH(f.Date) AS month,
  ROUND(MIN(f.Temperature), 2) AS min_temp,
  ROUND(MAX(f.Temperature), 2) AS max_temp,
  ROUND(AVG(f.Temperature), 2) AS avg_temp,
  ROUND(MIN(f.Fuel_Price), 2) AS min_fuel_price,
  ROUND(MAX(f.Fuel_Price), 2) AS max_fuel_price,
  ROUND(AVG(f.Fuel_Price), 2) AS avg_fuel_price
FROM features f
JOIN stores st ON f.Store = st.Store
GROUP BY f.Store, year, month
ORDER BY year, month, f.Store;


-- 8. Average Weekly Sales per Store by Year
SELECT 
    Store,
    YEAR(Date) AS sales_year,
    Round(AVG(Weekly_Sales),2) AS avg_sales
FROM sales
GROUP BY Store, sales_year
ORDER BY Store, sales_year;

-- 9. 4-Week Rolling Average of Weekly Sales
WITH weekly_totals AS (
    SELECT
        Store,
        Date,
        Round(SUM(Weekly_Sales),2) AS total_weekly_sales
    FROM sales
    GROUP BY Store, Date
)
SELECT
    Store,
    Date,
    total_weekly_sales,
    ROUND(
        AVG(total_weekly_sales) OVER (
            PARTITION BY Store
            ORDER BY Date
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_avg_4wk
FROM weekly_totals
ORDER BY Store, Date;


-- 10. Holiday Week Sales per Store
WITH holiday_sales_per_store AS (
  SELECT
    Store,
    Date,
    Round(SUM(Weekly_Sales),2) AS holiday_sales
  FROM sales
  WHERE IsHoliday = 'TRUE'
  GROUP BY Store, Date
)
SELECT
  t.Store,
  t.Date,
  t.holiday_sales
FROM holiday_sales_per_store t
ORDER BY t.Store;

-- 11. Department Sales Contribution to Store Total
WITH store_sales AS (
  SELECT Store, SUM(Weekly_Sales) AS store_total_sales
  FROM sales
  GROUP BY Store
)
SELECT
  s.Store,
  s.Dept,
  Round(SUM(s.Weekly_Sales),2) AS dept_sales,
  Round((SUM(s.Weekly_Sales) / ss.store_total_sales) * 100,2) AS dept_sales_pct
FROM sales s
JOIN store_sales ss ON s.Store = ss.Store
GROUP BY s.Store, s.Dept, ss.store_total_sales
ORDER BY s.Store, dept_sales_pct DESC;

-- 12. Sales Spike Detection
WITH sales_lag AS (
  SELECT
    Store,
    Dept,
    Date,
    Weekly_Sales,
    LAG(Weekly_Sales) OVER (PARTITION BY Store, Dept ORDER BY Date) AS prev_week_sales
  FROM sales
)
SELECT
  Store,
  Dept,
  Date,
  Weekly_Sales,
  prev_week_sales,
  CASE 
    WHEN prev_week_sales IS NOT NULL AND (Weekly_Sales > prev_week_sales * 1.5) THEN 'Spike'
    ELSE 'Normal'
  END AS sales_trend
FROM sales_lag
-- WHERE sales_trend = "Spike"
ORDER BY Store, Dept, Date;

-- 13. Markdown and Sales Totals by Store and Year
SELECT
  f.Store,
  YEAR(f.Date) AS sales_year,
  SUM(
    COALESCE(f.MarkDown1, 0) +
    COALESCE(f.MarkDown2, 0) +
    COALESCE(f.MarkDown3, 0) +
    COALESCE(f.MarkDown4, 0) +
    COALESCE(f.MarkDown5, 0)
  ) AS total_markdowns,
  SUM(s.Weekly_Sales) AS total_sales
FROM features f
JOIN sales s 
  ON f.Store = s.Store 
 AND f.Date = s.Date
GROUP BY f.Store, sales_year
ORDER BY Store, sales_year ASC;

-- 14. Year-over-Year Sales Growth by Store
SELECT
    s.Store,
    YEAR(s.Date) AS year,
    SUM(s.Weekly_Sales) AS total_sales,
    LAG(SUM(s.Weekly_Sales)) OVER (PARTITION BY s.Store ORDER BY YEAR(s.Date)) AS prev_year_sales,
    ROUND(
        (SUM(s.Weekly_Sales) - LAG(SUM(s.Weekly_Sales)) OVER (PARTITION BY s.Store ORDER BY YEAR(s.Date))) /
         LAG(SUM(s.Weekly_Sales)) OVER (PARTITION BY s.Store ORDER BY YEAR(s.Date)) * 100, 2
    ) AS yoy_growth_pct
FROM sales s
GROUP BY s.Store, year;

-- 15. Revenue Per Unit Area
SELECT
    s.Store,
    st.Category,
    st.Size,
    YEAR(s.Date) AS year,
    ROUND(AVG(s.Weekly_Sales), 2) AS avg_weekly_sales,
    ROUND(SUM(s.Weekly_Sales) / st.Size, 2) AS sales_per_unit_area
FROM sales s
JOIN stores st 
    ON s.Store = st.Store
GROUP BY s.Store, st.Category, st.Size, year
ORDER BY sales_per_unit_area Desc;