/*
    Data Warehouse Analytics: Business Intelligence Exploration
    -----------------------------------------------------------
    This script performs descriptive analytics on sales, customers, and product data 
    to extract key business metrics from the DataWarehouseAnalytics database.
*/

USE [DataWarehouseAnalytics];

-- ═══════════════════════════════════════════════════════════════════════
-- Explore database metadata
-- ═══════════════════════════════════════════════════════════════════════
SELECT * FROM INFORMATION_SCHEMA.TABLES;
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

-- ═══════════════════════════════════════════════════════════════════════
-- Basic data discovery
-- ═══════════════════════════════════════════════════════════════════════
SELECT DISTINCT country
FROM [gold.dim_customers];

SELECT DISTINCT 
    category, 
    subcategory, 
    product_name
FROM [gold.dim_products]
ORDER BY category, subcategory, product_name;

-- ═══════════════════════════════════════════════════════════════════════
-- Order date range and sales span in months
-- ═══════════════════════════════════════════════════════════════════════
SELECT 
    MIN(order_date)                                     AS first_order,
    MAX(order_date)                                     AS last_order,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date))   AS months_range
FROM [gold.fact_sales];

-- ═══════════════════════════════════════════════════════════════════════
-- Customer age metrics
-- ═══════════════════════════════════════════════════════════════════════
SELECT
    MIN(birthdate)                                      AS oldest,
    MAX(birthdate)                                      AS youngest,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE())           AS max_age,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE())           AS min_age
FROM [gold.dim_customers];

-- ═══════════════════════════════════════════════════════════════════════
-- Key sales and product metrics
-- ═══════════════════════════════════════════════════════════════════════
SELECT SUM(sales_amount)     AS total_sales FROM [gold.fact_sales];
SELECT SUM(quantity)         AS total_sold_items FROM [gold.fact_sales];
SELECT AVG(price)            AS avg_price FROM [gold.fact_sales];
SELECT COUNT(DISTINCT order_number)      AS total_orders FROM [gold.fact_sales];
SELECT COUNT(DISTINCT product_key)       AS total_products FROM [gold.dim_products];
SELECT COUNT(DISTINCT customer_id)       AS total_customers FROM [gold.dim_customers];
SELECT COUNT(DISTINCT customer_key)      AS customers_with_orders FROM [gold.fact_sales];

-- ═══════════════════════════════════════════════════════════════════════
-- Consolidated business metrics report
-- ═══════════════════════════════════════════════════════════════════════
SELECT 'Total Sales'               AS measure_name, SUM(sales_amount)          AS measure_value FROM [gold.fact_sales]
UNION ALL 
SELECT 'Total Quantity',                   SUM(quantity)                      FROM [gold.fact_sales]
UNION ALL 
SELECT 'Average Price',                    AVG(price)                         FROM [gold.fact_sales]
UNION ALL
SELECT 'Total Orders',                     COUNT(DISTINCT order_number)       FROM [gold.fact_sales]
UNION ALL
SELECT 'Total Products',                   COUNT(DISTINCT product_key)        FROM [gold.dim_products]
UNION ALL
SELECT 'Total Customers',                  COUNT(DISTINCT customer_id)        FROM [gold.dim_customers]
UNION ALL
SELECT 'Customers With Orders',            COUNT(DISTINCT customer_key)       FROM [gold.fact_sales];

-- ═══════════════════════════════════════════════════════════════════════
-- Customer distribution
-- ═══════════════════════════════════════════════════════════════════════
SELECT 
    country,
    COUNT(DISTINCT customer_key)          AS num_of_customers
FROM [gold.dim_customers]
GROUP BY country
ORDER BY num_of_customers DESC;

SELECT 
    gender,
    COUNT(DISTINCT customer_key)          AS gender_count
FROM [gold.dim_customers]
GROUP BY gender
ORDER BY gender_count DESC;

-- ═══════════════════════════════════════════════════════════════════════
-- Product distribution
-- ═══════════════════════════════════════════════════════════════════════
SELECT
    category,
    COUNT(DISTINCT product_key)           AS total_products
FROM [gold.dim_products]
GROUP BY category
ORDER BY total_products DESC;

SELECT
    category,
    AVG(cost)                             AS avg_cost
FROM [gold.dim_products]
GROUP BY category
ORDER BY avg_cost DESC;

-- ═══════════════════════════════════════════════════════════════════════
-- Revenue by product category
-- ═══════════════════════════════════════════════════════════════════════
SELECT
    p.category,
    SUM(f.sales_amount)                   AS total_revenue
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- ═══════════════════════════════════════════════════════════════════════
-- Revenue by customer
-- ═══════════════════════════════════════════════════════════════════════
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount)                   AS total_revenue
FROM [gold.dim_customers] c
LEFT JOIN [gold.fact_sales] f ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- ═══════════════════════════════════════════════════════════════════════
-- Sold items by country
-- ═══════════════════════════════════════════════════════════════════════
SELECT
    c.country,
    SUM(f.quantity)                       AS total_quantity
FROM [gold.dim_customers] c
LEFT JOIN [gold.fact_sales] f ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_quantity DESC;

-- ═══════════════════════════════════════════════════════════════════════
-- Top 5 products by revenue
-- ═══════════════════════════════════════════════════════════════════════
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount)                   AS total_revenue
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- ═══════════════════════════════════════════════════════════════════════
-- Bottom 5 products by revenue
-- ═══════════════════════════════════════════════════════════════════════
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount)                   AS total_revenue
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- ═══════════════════════════════════════════════════════════════════════
-- Alternative top 5 products by revenue using window function
-- ═══════════════════════════════════════════════════════════════════════
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount)               AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_product
    FROM [gold.fact_sales] f
    LEFT JOIN [gold.dim_products] p ON p.product_key = f.product_key
    GROUP BY p.product_name
) AS T
WHERE rank_product <= 5;

-- ═══════════════════════════════════════════════════════════════════════
-- Top 10 customers by revenue
-- ═══════════════════════════════════════════════════════════════════════
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount)                   AS total_revenue
FROM [gold.dim_customers] c
LEFT JOIN [gold.fact_sales] f ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- ═══════════════════════════════════════════════════════════════════════