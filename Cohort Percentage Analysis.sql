-- This query calculates the retention rate of users in a monthly cohort. 

-- Create a temporary table 'customer' to select user_id and cohort month based on the first order they placed. 

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

-- Create a temporary table 'base' to calculate the number of orders placed by each user in a given month and associate each order to its respective cohort month.

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

-- Create a temporary table 'dates' to generate a sequence of months between each user's cohort month and the current date.

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

-- Create a temporary table 'cohort' to calculate the number of users who made their first purchase in the cohort month and the number of those users who made a purchase in each subsequent month.

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

-- Create a temporary table 'cohort_initial_users' to select the initial number of users in each cohort month.

cohort_initial_users AS (
  SELECT 
    cohort_month, 
    num_users AS initial_users 
  FROM 
    cohort 
  WHERE 
    cohort_month = order_month
), 

-- Create a temporary table 'rownumber' to assign a row number to each cohort month and order month combination.

rownumber AS (
  SELECT 
    cohort_month, 
    order_month, 
    num_users, 
    row_number() OVER (PARTITION BY cohort_month) as r1 
  FROM 
    cohort
) 

-- Select the cohort month, order months, and retention rate for each cohort month and order month combination.

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
  LEFT JOIN cohort_initial_users ON rownumber.c
  
