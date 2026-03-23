-- Cohort retention analysis
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Cohort definition:
--   user's first non-cancelled order month
-- Retention definition:
--   user places another non-cancelled order in a later month

-- Query 1: monthly retention cohort table in long format
WITH valid_orders AS (
  SELECT
    order_id,
    user_id,
    DATE(created_at) AS order_date
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
),
user_cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC(MIN(order_date), MONTH) AS cohort_month
  FROM valid_orders
  GROUP BY user_id
),
cohort_activity AS (
  SELECT
    uc.cohort_month,
    DATE_TRUNC(vo.order_date, MONTH) AS activity_month,
    DATE_DIFF(
      DATE_TRUNC(vo.order_date, MONTH),
      uc.cohort_month,
      MONTH
    ) AS months_since_first_order,
    vo.user_id
  FROM valid_orders AS vo
  JOIN user_cohorts AS uc
    ON vo.user_id = uc.user_id
),
cohort_sizes AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT user_id) AS cohort_size
  FROM user_cohorts
  GROUP BY cohort_month
)
SELECT
  ca.cohort_month,
  ca.activity_month,
  ca.months_since_first_order,
  cs.cohort_size,
  COUNT(DISTINCT ca.user_id) AS retained_users,
  ROUND(
    SAFE_DIVIDE(COUNT(DISTINCT ca.user_id), cs.cohort_size) * 100,
    2
  ) AS retention_rate
FROM cohort_activity AS ca
JOIN cohort_sizes AS cs
  ON ca.cohort_month = cs.cohort_month
GROUP BY
  ca.cohort_month,
  ca.activity_month,
  ca.months_since_first_order,
  cs.cohort_size
ORDER BY ca.cohort_month, ca.months_since_first_order;

-- Query 2: retention with revenue by cohort month
WITH valid_orders AS (
  SELECT
    order_id,
    user_id,
    DATE(created_at) AS order_date
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
),
valid_order_revenue AS (
  SELECT
    oi.order_id,
    ROUND(SUM(oi.sale_price), 2) AS order_revenue
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  GROUP BY oi.order_id
),
user_cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC(MIN(order_date), MONTH) AS cohort_month
  FROM valid_orders
  GROUP BY user_id
)
SELECT
  uc.cohort_month,
  DATE_TRUNC(vo.order_date, MONTH) AS activity_month,
  DATE_DIFF(DATE_TRUNC(vo.order_date, MONTH), uc.cohort_month, MONTH) AS months_since_first_order,
  COUNT(DISTINCT vo.user_id) AS retained_users,
  COUNT(DISTINCT vo.order_id) AS orders,
  ROUND(SUM(vor.order_revenue), 2) AS revenue
FROM valid_orders AS vo
JOIN user_cohorts AS uc
  ON vo.user_id = uc.user_id
LEFT JOIN valid_order_revenue AS vor
  ON vo.order_id = vor.order_id
GROUP BY uc.cohort_month, activity_month, months_since_first_order
ORDER BY uc.cohort_month, months_since_first_order;

-- Query 3: simple repeat-purchase view for recruiter-friendly summary
WITH valid_orders AS (
  SELECT
    user_id,
    DATE(created_at) AS order_date
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
),
user_order_counts AS (
  SELECT
    user_id,
    COUNT(*) AS order_count,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
  FROM valid_orders
  GROUP BY user_id
)
SELECT
  COUNT(*) AS purchasing_users,
  COUNTIF(order_count = 1) AS one_time_buyers,
  COUNTIF(order_count >= 2) AS repeat_buyers,
  ROUND(SAFE_DIVIDE(COUNTIF(order_count >= 2), COUNT(*)) * 100, 2) AS repeat_buyer_rate,
  ROUND(AVG(order_count), 2) AS avg_orders_per_purchasing_user
FROM user_order_counts;
