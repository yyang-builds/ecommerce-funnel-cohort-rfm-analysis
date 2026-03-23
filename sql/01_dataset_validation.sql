-- TheLook E-commerce dataset validation
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Purpose:
--   1) confirm usable tables and date ranges
--   2) inspect event and order status coverage
--   3) establish baseline counts for downstream analysis

-- Query 1: high-level row counts across core tables
SELECT 'events' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.thelook_ecommerce.events`
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.thelook_ecommerce.orders`
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.thelook_ecommerce.order_items`
UNION ALL
SELECT 'users' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.thelook_ecommerce.users`
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.thelook_ecommerce.products`
ORDER BY table_name;

-- Query 2: date coverage for events, users, and orders
SELECT
  'events' AS table_name,
  MIN(DATE(created_at)) AS min_date,
  MAX(DATE(created_at)) AS max_date
FROM `bigquery-public-data.thelook_ecommerce.events`
UNION ALL
SELECT
  'users' AS table_name,
  MIN(DATE(created_at)) AS min_date,
  MAX(DATE(created_at)) AS max_date
FROM `bigquery-public-data.thelook_ecommerce.users`
UNION ALL
SELECT
  'orders' AS table_name,
  MIN(DATE(created_at)) AS min_date,
  MAX(DATE(created_at)) AS max_date
FROM `bigquery-public-data.thelook_ecommerce.orders`
ORDER BY table_name;

-- Query 3: event type distribution used to define the web funnel
SELECT
  event_type,
  COUNT(*) AS event_count,
  COUNT(DISTINCT session_id) AS distinct_sessions,
  COUNT(DISTINCT user_id) AS distinct_users
FROM `bigquery-public-data.thelook_ecommerce.events`
GROUP BY event_type
ORDER BY event_count DESC;

-- Query 4: order status distribution used to define valid purchase logic
SELECT
  status,
  COUNT(*) AS order_count,
  COUNT(DISTINCT user_id) AS distinct_customers,
  SUM(num_of_item) AS ordered_items
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status
ORDER BY order_count DESC;

-- Query 5: channel, browser, and geo values sanity check
SELECT
  traffic_source,
  browser,
  COALESCE(city, 'Unknown') AS city,
  COUNT(*) AS event_count
FROM `bigquery-public-data.thelook_ecommerce.events`
GROUP BY traffic_source, browser, city
ORDER BY event_count DESC
LIMIT 50;

-- Query 6: baseline metrics for the rest of the project
WITH valid_orders AS (
  SELECT
    order_id,
    user_id,
    DATE(created_at) AS order_date
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
),
valid_order_items AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN valid_orders AS vo
    ON oi.order_id = vo.order_id
)
SELECT
  (SELECT COUNT(DISTINCT session_id) FROM `bigquery-public-data.thelook_ecommerce.events`) AS sessions,
  (SELECT COUNT(DISTINCT user_id) FROM `bigquery-public-data.thelook_ecommerce.events` WHERE user_id IS NOT NULL) AS identified_event_users,
  (SELECT COUNT(*) FROM valid_orders) AS non_cancelled_orders,
  (SELECT COUNT(DISTINCT user_id) FROM valid_orders) AS purchasing_users,
  (SELECT ROUND(SUM(sale_price), 2) FROM valid_order_items) AS gross_merchandise_value,
  (SELECT ROUND(AVG(sale_price), 2) FROM valid_order_items) AS avg_item_sale_price;
