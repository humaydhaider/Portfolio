WITH customer AS (
  SELECT 
    user_id, 
    DATE_TRUNC(
      'month', 
      MIN(date_placed)
    ):: date AS cohort_month 
  FROM 
    order_order 
  WHERE 
    status = 'processed' 
    AND user_id IS NOT NULL 
  GROUP BY 
    user_id
), 
base AS (
  SELECT 
    order_order.user_id, 
    cohort_month, 
    DATE_TRUNC('month', date_placed):: date AS order_month, 
    COUNT(DISTINCT order_order.id) AS num_orders 
  FROM 
    order_order 
    JOIN customer ON order_order.user_id = customer.user_id 
  WHERE 
    status = 'processed' 
    AND order_order.user_id IS NOT NULL 
  GROUP BY 
    order_order.user_id, 
    order_month, 
    cohort_month
), 
dates AS (
  SELECT 
    user_id, 
    generate_series(
      cohort_month, 
      date_trunc('month', current_date):: date, 
      '1 month'
    ):: date AS order_month 
  FROM 
    customer
), 
cohort AS (
  SELECT 
    customer.cohort_month, 
    dates.order_month, 
    COUNT(DISTINCT base.user_id) AS num_users 
  FROM 
    customer 
    LEFT JOIN (
      SELECT 
        DISTINCT base.user_id, 
        dates.order_month 
      FROM 
        base 
        LEFT JOIN dates ON base.user_id = dates.user_id
    ) dates ON customer.user_id = dates.user_id 
    AND dates.order_month >= customer.cohort_month 
    LEFT JOIN base ON dates.user_id = base.user_id 
    AND dates.order_month = base.order_month 
  WHERE 
    dates.order_month IS NOT NULL 
  GROUP BY 
    1, 
    2
), 
cohort_initial_users AS (
  SELECT 
    cohort_month, 
    num_users AS initial_users 
  FROM 
    cohort 
  WHERE 
    cohort_month = order_month
), 
rownumber AS (
  SELECT 
    cohort_month, 
    order_month, 
    num_users, 
    row_number() OVER (PARTITION BY cohort_month) as r1 
  FROM 
    cohort
) 
SELECT 
  rownumber.cohort_month AS "Cohort Month", 
  r1 AS "Order Months", 
  CASE WHEN r1 = 1 THEN 100 ELSE (
    100 *(CASE WHEN r1 > 1 THEN num_users END) / (
      cohort_initial_users.initial_users
    ):: float
  ) END AS "Retention Rate" 
FROM 
  rownumber 
  LEFT JOIN cohort_initial_users ON rownumber.cohort_month = cohort_initial_users.cohort_month 
GROUP BY 
  1, 
  2, 
  3 
ORDER BY 
  1, 
  2;
