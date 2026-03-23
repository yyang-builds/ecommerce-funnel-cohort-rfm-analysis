-- Channel, device/browser, and geo performance
-- Dataset: bigquery-public-data.thelook_ecommerce
-- This file keeps session behavior and order performance separate to avoid
-- over-attributing revenue to unsupported device or session fields.

-- Query 1: session performance by traffic source and browser
WITH session_metrics AS (
  SELECT
    session_id,
    ANY_VALUE(user_id) AS user_id,
    ANY_VALUE(traffic_source) AS traffic_source,
    ANY_VALUE(browser) AS browser,
    COALESCE(ANY_VALUE(city), 'Unknown') AS city,
    COUNT(*) AS events_in_session,
    MAX(CASE WHEN event_type = 'product' THEN 1 ELSE 0 END) AS viewed_product,
    MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS added_to_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  GROUP BY session_id
)
SELECT
  traffic_source,
  browser,
  COUNT(*) AS sessions,
  COUNT(DISTINCT user_id) AS identified_users,
  ROUND(AVG(events_in_session), 2) AS avg_events_per_session,
  COUNTIF(viewed_product = 1) AS product_view_sessions,
  COUNTIF(added_to_cart = 1) AS cart_sessions,
  COUNTIF(purchased = 1) AS purchase_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased = 1), COUNT(*)) * 100, 2) AS session_purchase_rate
FROM session_metrics
GROUP BY traffic_source, browser
HAVING COUNT(*) >= 1000
ORDER BY session_purchase_rate DESC, sessions DESC;

-- Query 2: acquisition and geo performance using users plus non-cancelled orders
WITH valid_orders AS (
  SELECT
    order_id,
    user_id,
    DATE(created_at) AS order_date
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
),
order_revenue AS (
  SELECT
    order_id,
    ROUND(SUM(sale_price), 2) AS order_revenue
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY order_id
)
SELECT
  u.traffic_source,
  u.country,
  COALESCE(u.city, 'Unknown') AS city,
  COUNT(DISTINCT u.id) AS users,
  COUNT(DISTINCT vo.user_id) AS purchasing_users,
  COUNT(DISTINCT vo.order_id) AS orders,
  ROUND(SUM(orv.order_revenue), 2) AS revenue,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT vo.order_id), COUNT(DISTINCT vo.user_id)), 2) AS orders_per_purchasing_user,
  ROUND(SAFE_DIVIDE(SUM(orv.order_revenue), COUNT(DISTINCT vo.order_id)), 2) AS average_order_value,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT vo.user_id), COUNT(DISTINCT u.id)) * 100, 2) AS user_to_purchase_rate
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN valid_orders AS vo
  ON u.id = vo.user_id
LEFT JOIN order_revenue AS orv
  ON vo.order_id = orv.order_id
GROUP BY u.traffic_source, u.country, city
HAVING COUNT(DISTINCT u.id) >= 100
ORDER BY revenue DESC, orders DESC;

-- Query 3: top cities by purchase volume and conversion
WITH session_users AS (
  SELECT
    session_id,
    ANY_VALUE(user_id) AS user_id,
    COALESCE(ANY_VALUE(city), 'Unknown') AS session_city,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  GROUP BY session_id
)
SELECT
  session_city AS city,
  COUNT(*) AS sessions,
  COUNT(DISTINCT user_id) AS identified_users,
  COUNTIF(purchased = 1) AS purchase_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased = 1), COUNT(*)) * 100, 2) AS session_purchase_rate
FROM session_users
GROUP BY session_city
HAVING COUNT(*) >= 1000
ORDER BY purchase_sessions DESC, session_purchase_rate DESC;
