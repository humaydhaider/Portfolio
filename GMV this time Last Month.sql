SELECT 
  DATE(
    DATE_TRUNC(
      'month', order_order.date_placed
    )
  ) AS month, 
  ROUND(
    SUM(
      CASE WHEN DATE(order_order.date_placed) BETWEEN DATE(
        DATE_TRUNC('month', NOW())
      ) 
      AND DATE(NOW()) THEN (
        CASE WHEN order_orderdiscount.voucher_code NOT IN ('') THEN (
          order_order.total_incl_tax + order_orderdiscount.amount
        ) ELSE order_order.total_incl_tax END
      ) WHEN DATE(order_order.date_placed) BETWEEN DATE(
        DATE_TRUNC(
          'month', NOW() - INTERVAL '1 MONTH'
        )
      ) 
      AND DATE(NOW() - INTERVAL '1 MONTH') THEN (
        CASE WHEN order_orderdiscount.voucher_code NOT IN ('') THEN (
          order_order.total_incl_tax + order_orderdiscount.amount
        ) ELSE order_order.total_incl_tax END
      ) ELSE 0 END
    ), 
    0
  ) AS gmv_including_promo 
FROM 
  order_order 
  LEFT JOIN order_orderdiscount ON order_order.id = order_orderdiscount.order_id 
WHERE 
  order_order.status NOT IN ('cancelled', 'Cancelled') 
GROUP BY 
  1
