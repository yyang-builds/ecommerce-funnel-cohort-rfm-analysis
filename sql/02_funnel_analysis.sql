-- Web funnel analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Funnel logic:
--   session -> home -> department -> product -> cart -> purchase
-- The shorter "core commerce funnel" focuses on:
--   product -> cart -> purchase
-- because nearly every tracked session already contains a product event.

-- Query 1: session-level detailed funnel
WITH session_flags AS (
  SELECT
    session_id,
    MIN(DATE(created_at)) AS session_date,
    ANY_VALUE(user_id) AS user_id,
    ANY_VALUE(traffic_source) AS traffic_source,
    ANY_VALUE(browser) AS browser,
    COALESCE(ANY_VALUE(city), 'Unknown') AS city,
    MAX(CASE WHEN event_type = 'home' THEN 1 ELSE 0 END) AS reached_home,
    MAX(CASE WHEN event_type = 'department' THEN 1 ELSE 0 END) AS reached_department,
    MAX(CASE WHEN event_type = 'product' THEN 1 ELSE 0 END) AS reached_product,
    MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS reached_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase
  FROM `bigquery-public-data.thelook_ecommerce.events`
  GROUP BY session_id
),
funnel_steps AS (
  SELECT 1 AS step_order, 'session' AS step_name, COUNT(*) AS sessions_at_step
  FROM session_flags
  UNION ALL
  SELECT 2, 'home', COUNTIF(reached_home = 1)
  FROM session_flags
  UNION ALL
  SELECT 3, 'department', COUNTIF(reached_home = 1 AND reached_department = 1)
  FROM session_flags
  UNION ALL
  SELECT 4, 'product', COUNTIF(reached_home = 1 AND reached_department = 1 AND reached_product = 1)
  FROM session_flags
  UNION ALL
  SELECT 5, 'cart', COUNTIF(reached_home = 1 AND reached_department = 1 AND reached_product = 1 AND reached_cart = 1)
  FROM session_flags
  UNION ALL
  SELECT 6, 'purchase', COUNTIF(reached_home = 1 AND reached_department = 1 AND reached_product = 1 AND reached_cart = 1 AND reached_purchase = 1)
  FROM session_flags
)
SELECT
  step_name,
  sessions_at_step,
  LAG(sessions_at_step) OVER (ORDER BY step_order) AS prior_step_sessions,
  ROUND(
    SAFE_DIVIDE(
      sessions_at_step,
      LAG(sessions_at_step) OVER (ORDER BY step_order)
    ) * 100,
    2
  ) AS step_to_step_conversion_rate,
  ROUND(
    SAFE_DIVIDE(
      sessions_at_step,
      FIRST_VALUE(sessions_at_step) OVER (ORDER BY step_order)
    ) * 100,
    2
  ) AS overall_funnel_conversion_rate
FROM funnel_steps
ORDER BY step_order;

-- Query 2: core commerce funnel from product view to purchase
WITH session_flags AS (
  SELECT
    session_id,
    MAX(CASE WHEN event_type = 'product' THEN 1 ELSE 0 END) AS viewed_product,
    MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS added_to_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  GROUP BY session_id
),
core_funnel AS (
  SELECT 1 AS step_order, 'product_view' AS step_name, COUNTIF(viewed_product = 1) AS sessions_at_step
  FROM session_flags
  UNION ALL
  SELECT 2, 'add_to_cart', COUNTIF(viewed_product = 1 AND added_to_cart = 1)
  FROM session_flags
  UNION ALL
  SELECT 3, 'purchase', COUNTIF(viewed_product = 1 AND added_to_cart = 1 AND purchased = 1)
  FROM session_flags
)
SELECT
  step_name,
  sessions_at_step,
  ROUND(
    SAFE_DIVIDE(
      sessions_at_step,
      FIRST_VALUE(sessions_at_step) OVER (ORDER BY step_order)
    ) * 100,
    2
  ) AS overall_conversion_rate
FROM core_funnel
ORDER BY step_order;

-- Query 3: channel and browser performance through the core funnel
WITH session_flags AS (
  SELECT
    session_id,
    ANY_VALUE(traffic_source) AS traffic_source,
    ANY_VALUE(browser) AS browser,
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
  COUNTIF(viewed_product = 1) AS product_view_sessions,
  COUNTIF(viewed_product = 1 AND added_to_cart = 1) AS add_to_cart_sessions,
  COUNTIF(viewed_product = 1 AND added_to_cart = 1 AND purchased = 1) AS purchase_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(viewed_product = 1), COUNT(*)) * 100, 2) AS product_view_rate,
  ROUND(SAFE_DIVIDE(COUNTIF(viewed_product = 1 AND added_to_cart = 1), COUNTIF(viewed_product = 1)) * 100, 2) AS cart_rate_from_product_view,
  ROUND(SAFE_DIVIDE(COUNTIF(viewed_product = 1 AND added_to_cart = 1 AND purchased = 1), COUNTIF(viewed_product = 1 AND added_to_cart = 1)) * 100, 2) AS purchase_rate_from_cart,
  ROUND(SAFE_DIVIDE(COUNTIF(viewed_product = 1 AND added_to_cart = 1 AND purchased = 1), COUNT(*)) * 100, 2) AS session_to_purchase_rate
FROM session_flags
GROUP BY traffic_source, browser
HAVING COUNT(*) >= 1000
ORDER BY session_to_purchase_rate DESC, sessions DESC;
