WITH orders1 AS 
(
WITH bulk as (SELECT order_id, SUM(COALESCE(discount,0)) AS bulk_discount FROM order_items WHERE CAST(created_at - INTERVAL '15HRS' AS DATE) >= '2023-11-01' GROUP BY order_id )

SELECT 
orders.user_id AS "Customer ID", 
retailers.phone AS "Phone Number",
cities.name AS "City",
CAST(orders.created_at - INTERVAL '15HRS' AS DATE) AS "Order Cycle Date",
orders.master_order_id,
-- COUNT(DISTINCT orders.master_order_id) AS "Number of Orders",
-- COUNT(DISTINCT CASE WHEN orders.status IN (4,5) THEN orders.master_order_id END) AS "Delivered Master Orders",
-- SUM(order_skus.ordered_qty * order_skus.price) AS "GMV",
SUM(CASE WHEN orders.status IN (4,5) THEN (COALESCE(order_items.picked_qty, 0) - COALESCE(order_items.return_qty, 0)) * order_items.price ELSE 0 END) AS "NMV",
SUM(CASE WHEN orders.status <> 6 THEN COALESCE(order_payments.total_discount,0) - bulk.bulk_discount - COALESCE(orders.special_discount,0)END) AS "Promos Discount",
SUM(CASE WHEN order_payments.payment_types_id = 4 AND orders.status <> 6 THEN  order_payments.amount ELSE 0 END) AS "Coins Compensation"


FROM orders 
LEFT JOIN order_details ON orders.id = order_details.order_id  
LEFT JOIN order_items ON order_items.order_id = orders.id
LEFT JOIN bulk ON bulk.order_id = orders.id
LEFT JOIN order_payments ON order_payments.order_id = orders.id
LEFT JOIN retailers ON retailers.user_id = orders.user_id
LEFT JOIN cities ON cities.id = retailers.city_id
WHERE orders.vertical_id = 1 
AND CAST(orders.created_at - INTERVAL '15HRS' AS DATE) >= '2023-11-01' 
GROUP BY 1,2,3,4,5
),
base_CTE AS 
(
SELECT oo."Customer ID", oo."Phone Number", oo."City",
(
    CASE 
        WHEN SUM("NMV") >= 50000 AND SUM("NMV") < 100000 THEN 'Silver'
        WHEN SUM("NMV") >= 100000 AND SUM("NMV") < 200000 THEN 'Gold'
        WHEN SUM("NMV") >= 200000 THEN 'Platinum' 
        ELSE 'Bronze' END
) AS "Base Segment",
SUM("NMV") AS "Base NMV",
SUM("Coins Compensation") AS "Base Coins Comp",
SUM("Promos Discount") AS "Base Promo Disc",
COUNT(DISTINCT master_order_id) AS "Orders - Base"


FROM orders1 oo 
WHERE TRUE 
[[AND oo."Order Cycle Date" BETWEEN {{FROM}} AND {{TO}}]]
GROUP BY 1,2,3
),
following_cte AS 
(
SELECT oo."Customer ID", oo."Phone Number", oo."City",
(
    CASE 
        WHEN SUM("NMV") >= 50000 AND SUM("NMV") < 100000 THEN 'Silver'
        WHEN SUM("NMV") >= 100000 AND SUM("NMV") < 200000 THEN 'Gold'
        WHEN SUM("NMV") >= 200000 THEN 'Platinum' 
        ELSE 'Bronze' END
) AS "Current Segment",
SUM("NMV") AS "Current NMV",
SUM("Coins Compensation") AS "Current Coins Comp",
SUM("Promos Discount") AS "Current Promo Disc",
COUNT(DISTINCT master_order_id) AS "Current Orders"


FROM orders1 oo 
WHERE TRUE 
[[AND oo."Order Cycle Date" BETWEEN {{From}} AND {{To}}]]
GROUP BY 1,2,3
) 

SELECT base_cte.*, 
       "Current Segment",
       "Current NMV",
       "Current Orders",
       "Current Coins Comp",
       "Current Promo Disc",
(CASE 
    WHEN "Current Segment" <> "Base Segment" THEN 'Migrated' ELSE NULL END) AS "Migration Status",
    ("Current NMV" - "Base NMV") AS "NMV Difference from Base Date"
    
FROM base_cte 
LEFT JOIN following_cte ON base_cte."Customer ID" = following_cte."Customer ID" 

