-- RFM segmentation
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Scoring method:
--   Recency: lower days since last order = better score
--   Frequency: more orders = better score
--   Monetary: more revenue = better score

-- Query 1: user-level RFM table
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
),
user_rfm_base AS (
  SELECT
    vo.user_id,
    MIN(vo.order_date) AS first_order_date,
    MAX(vo.order_date) AS last_order_date,
    DATE_DIFF(
      (SELECT MAX(order_date) FROM valid_orders),
      MAX(vo.order_date),
      DAY
    ) AS recency_days,
    COUNT(DISTINCT vo.order_id) AS frequency_orders,
    ROUND(SUM(orv.order_revenue), 2) AS monetary_value
  FROM valid_orders AS vo
  LEFT JOIN order_revenue AS orv
    ON vo.order_id = orv.order_id
  GROUP BY vo.user_id
),
scored AS (
  SELECT
    *,
    6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency_orders ASC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
  FROM user_rfm_base
)
SELECT
  user_id,
  first_order_date,
  last_order_date,
  recency_days,
  frequency_orders,
  monetary_value,
  recency_score,
  frequency_score,
  monetary_score,
  CONCAT(
    CAST(recency_score AS STRING),
    CAST(frequency_score AS STRING),
    CAST(monetary_score AS STRING)
  ) AS rfm_score,
  CASE
    WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
    WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3 THEN 'Loyal Customers'
    WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promising'
    WHEN recency_score = 5 AND frequency_score = 1 THEN 'New Customers'
    WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
    WHEN recency_score = 1 AND frequency_score >= 4 THEN 'Cannot Lose Them'
    WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Hibernating'
    ELSE 'Potential Loyalists'
  END AS rfm_segment
FROM scored
ORDER BY monetary_value DESC;

-- Query 2: recruiter-friendly RFM segment summary
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
),
user_rfm_base AS (
  SELECT
    vo.user_id,
    DATE_DIFF(
      (SELECT MAX(order_date) FROM valid_orders),
      MAX(vo.order_date),
      DAY
    ) AS recency_days,
    COUNT(DISTINCT vo.order_id) AS frequency_orders,
    ROUND(SUM(orv.order_revenue), 2) AS monetary_value
  FROM valid_orders AS vo
  LEFT JOIN order_revenue AS orv
    ON vo.order_id = orv.order_id
  GROUP BY vo.user_id
),
scored AS (
  SELECT
    *,
    6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency_orders ASC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
  FROM user_rfm_base
),
segmented AS (
  SELECT
    user_id,
    frequency_orders,
    monetary_value,
    CASE
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
      WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3 THEN 'Loyal Customers'
      WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promising'
      WHEN recency_score = 5 AND frequency_score = 1 THEN 'New Customers'
      WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
      WHEN recency_score = 1 AND frequency_score >= 4 THEN 'Cannot Lose Them'
      WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Hibernating'
      ELSE 'Potential Loyalists'
    END AS rfm_segment
  FROM scored
)
SELECT
  rfm_segment,
  COUNT(*) AS customers,
  ROUND(AVG(frequency_orders), 2) AS avg_orders_per_customer,
  ROUND(AVG(monetary_value), 2) AS avg_revenue_per_customer,
  ROUND(SUM(monetary_value), 2) AS total_revenue
FROM segmented
GROUP BY rfm_segment
ORDER BY total_revenue DESC;
