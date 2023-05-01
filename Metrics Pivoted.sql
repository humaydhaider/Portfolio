WITH monthly_gmv AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    SUM(total_incl_tax) AS GMV 
  FROM 
    order_order 
  WHERE 
    {{partner_id}} 
    AND status NOT IN ('cancelled', 'cancelled') 
  GROUP BY 
    1
), 
monthly_repeat_gmv AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    SUM(total_incl_tax) AS repeat_GMV 
  FROM 
    (
      SELECT 
        *, 
        ROW_NUMBER() OVER (
          PARTITION BY user_id 
          ORDER BY 
            date_placed
        ) AS order_number 
      FROM 
        order_order 
      WHERE 
        {{partner_id}} 
        AND status NOT IN ('cancelled', 'cancelled')
    ) subq 
  WHERE 
    order_number > 1 
  GROUP BY 
    1
), 
monthly_total_users AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    COUNT(DISTINCT user_id) AS total_users 
  FROM 
    order_order 
  WHERE 
    {{partner_id}} 
    AND status NOT IN ('cancelled', 'cancelled') 
  GROUP BY 
    1
), 
monthly_first_time_users AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    COUNT(DISTINCT user_id) AS first_time_users 
  FROM 
    (
      SELECT 
        *, 
        ROW_NUMBER() OVER (
          PARTITION BY user_id 
          ORDER BY 
            date_placed
        ) AS order_number 
      FROM 
        order_order 
      WHERE 
        {{partner_id}} 
        AND status NOT IN ('cancelled', 'cancelled')
    ) subq 
  WHERE 
    order_number = 1 
  GROUP BY 
    1
), 
monthly_total_orders AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    COUNT(id) AS total_orders 
  FROM 
    order_order 
  WHERE 
    {{partner_id}} 
    AND status NOT IN ('cancelled', 'cancelled') 
  GROUP BY 
    1
), 
monthly_repeat_orders AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    COUNT(id) AS repeat_orders 
  FROM 
    (
      SELECT 
        *, 
        ROW_NUMBER() OVER (
          PARTITION BY user_id 
          ORDER BY 
            date_placed
        ) AS order_number 
      FROM 
        order_order 
      WHERE 
        {{partner_id}} 
        AND status NOT IN ('cancelled', 'cancelled')
    ) subq 
  WHERE 
    order_number > 1 
  GROUP BY 
    1
), 
CTE AS (
  SELECT 
    DATE(monthly_gmv.month) as Month, 
    monthly_gmv.GMV AS GMV, 
    monthly_repeat_gmv.repeat_GMV AS repeat_GMV, 
    monthly_total_users.total_users AS total_users, 
    monthly_first_time_users.first_time_users AS first_time_users, 
    monthly_total_orders.total_orders AS total_orders, 
    monthly_repeat_orders.repeat_orders AS repeat_orders 
  FROM 
    monthly_gmv FULL 
    OUTER JOIN monthly_repeat_gmv ON monthly_gmv.month = monthly_repeat_gmv.month FULL 
    OUTER JOIN monthly_first_time_users ON monthly_gmv.month = monthly_first_time_users.month FULL 
    OUTER JOIN monthly_total_orders ON monthly_gmv.month = monthly_total_orders.month FULL 
    OUTER JOIN monthly_repeat_orders ON monthly_gmv.month = monthly_repeat_orders.month FULL 
    OUTER JOIN monthly_total_users ON monthly_gmv.month = monthly_total_users.month
) 
SELECT 
  month, 
  'GMV' metrics, 
  gmv AS 
values 
FROM 
  CTE 
UNION ALL 
SELECT 
  month, 
  'Repeat GMV' metrics, 
  repeat_gmv 
FROM 
  CTE 
UNION ALL 
SELECT 
  month, 
  'Total Users' metrics, 
  total_users 
FROM 
  CTE 
UNION ALL 
SELECT 
  month, 
  'First Time Users' metrics, 
  first_time_users 
FROM 
  CTE 
UNION ALL 
SELECT 
  month, 
  'Total Orders' metrics, 
  total_orders 
FROM 
  CTE 
UNION ALL 
SELECT 
  month, 
  'Repeat Orders' metrics, 
  repeat_orders 
FROM 
  CTE 
ORDER BY 
  month DESC, 
values 
  DESC
