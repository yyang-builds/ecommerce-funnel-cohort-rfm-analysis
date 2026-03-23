# Data Dictionary

## Dataset
- Source: `bigquery-public-data.thelook_ecommerce`
- Core tables used in this project:
  - `events`
  - `orders`
  - `order_items`
  - `users`
  - `products`

## Table Overview

### `events`
Session-level behavioral data used for funnel and browsing analysis.

Key fields:
- `session_id`: unique session identifier
- `user_id`: user identifier when known
- `created_at`: event timestamp
- `event_type`: event category such as `home`, `department`, `product`, `cart`, `purchase`, `cancel`
- `traffic_source`: acquisition source tied to the event
- `browser`: browser/device proxy used for session analysis
- `city`, `state`: event-level geography
- `uri`: page path
- `sequence_number`: event order within the session

### `orders`
Order-level purchase records used for cohort and customer analysis.

Key fields:
- `order_id`: unique order identifier
- `user_id`: customer identifier
- `status`: order lifecycle status
- `created_at`: order creation timestamp
- `returned_at`, `shipped_at`, `delivered_at`: downstream fulfillment timestamps
- `num_of_item`: number of items in the order

### `order_items`
Line-item level revenue table used to calculate sales and product-level spend.

Key fields:
- `id`: unique order item identifier
- `order_id`: order identifier
- `user_id`: customer identifier
- `product_id`: product identifier
- `status`: line-item status
- `created_at`: line-item creation timestamp
- `sale_price`: item revenue

### `users`
Customer profile and acquisition table used for geo and source analysis.

Key fields:
- `id`: unique user identifier
- `created_at`: user creation timestamp
- `traffic_source`: user acquisition source
- `country`, `city`, `state`: customer geography
- `age`, `gender`: customer attributes
- `latitude`, `longitude`, `user_geom`: location fields

### `products`
Reference table used for product and category context.

Key fields:
- `id`: product identifier
- `name`: product name
- `brand`: brand name
- `category`, `department`: merchandising hierarchy
- `retail_price`: list price
- `cost`: product cost

## Metric Definitions

### Funnel Metrics
- `sessions`: distinct `session_id` values in `events`
- `product_view_sessions`: sessions with at least one `event_type = 'product'`
- `cart_sessions`: sessions with at least one `event_type = 'cart'`
- `purchase_sessions`: sessions with at least one `event_type = 'purchase'`
- `session_purchase_rate`: `purchase_sessions / sessions`
- `purchase_rate_from_cart`: `purchase_sessions / cart_sessions`

### Order and Revenue Metrics
- `non_cancelled_orders`: orders where `status != 'Cancelled'`
- `purchasing_users`: distinct users with at least one non-cancelled order
- `revenue`: sum of `order_items.sale_price` for valid orders in scope
- `average_order_value`: `revenue / distinct orders`
- `orders_per_purchasing_user`: `distinct orders / distinct purchasing users`

### Retention Metrics
- `cohort_month`: month of the customer's first non-cancelled order
- `activity_month`: later month in which the same customer placed a non-cancelled order
- `months_since_first_order`: number of months between `cohort_month` and `activity_month`
- `retention_rate`: `retained_users / cohort_size`
- `repeat_buyer_rate`: share of purchasing users with 2 or more valid orders

### RFM Metrics
- `recency_days`: days since the user's last non-cancelled order, measured against the latest order date in the dataset
- `frequency_orders`: count of distinct valid orders per user
- `monetary_value`: sum of valid order revenue per user
- `rfm_score`: concatenated recency, frequency, and monetary scores from 1 to 5
- `rfm_segment`: descriptive segment label such as `Champions`, `Loyal Customers`, or `At Risk`

## Analysis Assumptions
- Funnel analysis uses the `events` table and measures behavior at the session level.
- Cohort and RFM analysis use `orders` and `order_items`.
- This project excludes `Cancelled` orders from retention, RFM, and order revenue calculations.
- Browser is used as the practical device proxy because the public dataset does not expose a richer device category field in the same way GA4 export does.
- The event dataset appears to start late in the browsing journey for many sessions, so product view is treated as the practical funnel entry point for conversion analysis.
