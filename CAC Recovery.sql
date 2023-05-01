-- Get the first order date for each user
WITH first_orders AS (
  SELECT 
    user_id, 
    DATE(
      MIN(date_placed)
    ) as first_order_date 
  FROM 
    order_order 
  WHERE 
    status NOT IN ('cancelled', 'Cancelled') 
  GROUP BY 
    1
), 
-- Calculate rolling totals and LTV for each user and order
rolling AS (
  SELECT 
    user_id, 
    DATE(date_placed) as date1, 
    total_incl_tax, 
    SUM(total_incl_tax) OVER (
      PARTITION BY user_id 
      ORDER BY 
        DATE(date_placed)
    ) AS rolling_sum, 
    SUM(0.05 * total_incl_tax) OVER (
      PARTITION BY user_id 
      ORDER BY 
        DATE(date_placed)
    ) AS rolling_LTV, 
    RANK() OVER (
      PARTITION BY user_id 
      ORDER BY 
        DATE(date_placed)
    ) as rank1 
  FROM 
    order_order 
  WHERE 
    status NOT IN ('cancelled', 'Cancelled') 
    AND user_id IS NOT NULL 
  ORDER BY 
    1, 
    2
), 
-- Calculate LTV order and rank for each user 
ltv_cte AS (
  SELECT 
    user_id, 
    rank1, 
    MIN(date1) as ltv_order, 
    RANK() OVER (
      PARTITION BY user_id 
      ORDER BY 
        date1
    ) as rank2 
  FROM 
    rolling 
  WHERE 
    rolling_LTV >= 200 
  GROUP BY 
    1, 
    2, 
    date1
) -- Join the LTV order and first order dates and calculate the difference
SELECT 
  ltv_cte.user_id, 
  first_order_date, 
  ltv_order, 
  (ltv_order - first_order_date) as recovery_days 
FROM 
  ltv_cte 
  LEFT JOIN first_orders ON ltv_cte.user_id = first_orders.user_id 
WHERE 
  rank2 = 1 
GROUP BY 
  1, 
  2, 
  3 
ORDER BY 
  1, 
  2 asc;
