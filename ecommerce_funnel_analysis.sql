-- ========================================================
-- E-commerce Funel Analysis
-- =========================================================
-- Tables: events(user_id, event_type, timestamp, device, source),
--         orders(order_id, user_id, amount, discount, status, timestamp),
--         products(product_id, name, category, price)
-- Sample data in ./data/  (events.csv, orders.csv, products.csv)
-- Dialect: MySQL.
-- ========================================================

-- Query 1 : Select All the Table

use ecomerce_funel;
select * from events;
select * from orders;
select * from products;

-- Query 2 : Full Conversion Funnel by traffic Source

WITH funnel AS (
SELECT source,
COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN 	user_id END) AS viewers,
COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN 	user_id END) AS added_cart,
COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN 	user_id END) AS started_checkout,
COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN 	user_id END) AS purchasers
FROM events
GROUP BY source
)
SELECT 
source,
viewers,
added_cart,
ROUND(added_cart * 100.0/ NULLIF(viewers,0),1) AS view_to_cart_pct,
ROUND(started_checkout * 100.0/ NULLIF(added_cart,0),1) AS cart_to_checkout_pct,
ROUND(purchasers * 100.0/ NULLIF(viewers,0),1) AS overall_conversion_pct
FROM funnel
ORDER BY  overall_conversion_pct DESC;


-- Query 3 : Weekly Cohort Conversion trends
WITH 	weekly_cohorts AS(
SELECT 
YEARWEEK(MIN(timestamp),1) AS cohort_week,
user_id
FROM
events

GROUP BY user_id
)
SELECT
wc.cohort_week,
COUNT(DISTINCT wc.user_id) AS cohort_size,
COUNT(DISTINCT o.user_id)AS purchasers,
ROUND(COUNT(DISTINCT o.user_id) * 100.0/ COUNT(DISTINCT wc.user_id),1) AS conversion_rate
FROM weekly_cohorts wc
LEFT JOIN orders o
ON wc.user_id = o.user_id
AND
o.status = 'completed'
GROUP BY wc.cohort_week
ORDER BY wc.cohort_week;

-- Query 4 : Drop-off Analysis by device type

WITH device_funnel AS (
  SELECT
    device,
    event_type,
    COUNT(DISTINCT user_id) AS users
  FROM events
  GROUP BY device, event_type
)
SELECT
  device,
  MAX(CASE WHEN event_type = 'page_view' THEN users END) AS page_views,
  MAX(CASE WHEN event_type = 'add_to_cart' THEN users END) AS add_to_cart,
  MAX(CASE WHEN event_type = 'purchase' THEN users END) AS purchases,
  ROUND(
    MAX(CASE WHEN event_type = 'purchase' THEN users END) * 100.0
    / NULLIF(MAX(CASE WHEN event_type = 'page_view' THEN users END), 0), 1
  ) AS conversion_rate
FROM device_funnel
GROUP BY device;

-- Query 5 : Revenue Analysis by Traffic Source
WITH user_source AS (
SELECT 
user_id,
source
FROM events
GROUP BY user_id, source
)	
SELECT
us.source,
COUNT(o.order_id) AS total_orders,
SUM(o.amount) AS total_revenue,
ROUND(AVG(o.amount),2) AS average_order_value
FROM user_source us
JOIN orders o
ON  us.user_id = o.user_id
WHERE o.status = 'completed'
GROUP BY us.source
ORDER BY total_revenue DESC;




