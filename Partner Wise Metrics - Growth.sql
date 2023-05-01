WITH raw_data AS (
  SELECT 
    DATE_TRUNC('month', date_placed) AS month, 
    partner_id AS partner_id, 
    partner_partner.name AS partner_name, 
    ROUND(
      SUM(total_incl_tax), 
      0
    ) AS GMV, 
    COUNT(DISTINCT user_id) AS Active_Users, 
    RANK() OVER (
      PARTITION BY DATE_TRUNC('month', date_placed) 
      ORDER BY 
        SUM(total_incl_tax) DESC
    ) AS rank1 
  FROM 
    order_order 
    LEFT JOIN partner_partner ON order_order.partner_id = partner_partner.id 
  WHERE 
    status NOT IN ('cancelled', 'Cancelled') 
  GROUP BY 
    month, 
    partner_id, 
    partner_name
), 
gmv_growth AS (
  SELECT 
    month, 
    partner_id, 
    partner_name, 
    GMV, 
    Active_Users, 
    LAG(GMV) OVER (
      PARTITION BY partner_id 
      ORDER BY 
        month
    ) AS prev_GMV, 
    LAG(Active_Users) OVER (
      PARTITION BY partner_id 
      ORDER BY 
        month
    ) AS prev_users 
  FROM 
    raw_data --WHERE rank1 <= 10
    ) 
SELECT 
  DATE(month) AS month, 
  partner_id, 
  partner_name, 
  GMV, 
  ROUND(
    (GMV - prev_GMV) / NULLIF(prev_GMV, 0) * 100.0, 
    2
  ) AS incremental_gmv_growth, 
  Active_Users, 
  (Active_Users - prev_users):: float / prev_users * 100 AS user_growth 
FROM 
  gmv_growth 
WHERE 
  month >= '2023-01-01' 
  AND prev_GMV IS NOT NULL 
ORDER BY 
  1 ASC, 
  4 DESC, 
  5 DESC
