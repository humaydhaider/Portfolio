WITH customers AS (
SELECT cities.name AS "City", CAST(users.created_at + Interval '5HRS' AS DATE) AS "Signup Date",
retailers.user_id AS "Customer ID", users.name AS "Retailer Name", retailers.store_name AS "Store Name", retailers.phone AS "Mobile Number", areas.name AS "Zone", sub_areas.name AS "Area",
(retailers.latlng#>> '{lng}'::text[]) AS "lng",
(retailers.latlng#>> '{lat}'::text[]) AS "lat", 
retailers.cnic_number AS "CNIC",
CASE WHEN users.is_verify = True THEN 'Verified' ELSE 'Not Verified' END as verified_user,
(CASE WHEN users.refer_by IS NULL THEN 'Organic Signup' ELSE 'Inorganic Signup' END) Signup_agent,
user_types.user_type_slug AS "User Type",
CAST(NOW() AS DATE) - CAST(users.created_at + Interval '5HRS' AS DATE) AS "Customer Age",
--(CAST(NOW() AS DATE) - CAST(users.created_at + Interval '5HRS' AS DATE))/30 ::FLOAT "Customer Age Months",
MAX(CAST(orders.created_at - INTERVAL '10HRS' AS DATE)) AS "Last Order Date"

From retailers
LEFT JOIN orders ON retailers.user_id = orders.user_id
LEFT JOIN order_details ON orders.id = order_details.order_id  
LEFT JOIN cities ON cities.id = COALESCE(order_details.city_id, retailers.city_id)
LEFT JOIN areas ON areas.id = COALESCE(order_details.area_id, retailers.area_id) 
LEFT JOIN sub_areas ON sub_areas.id = COALESCE(order_details.sub_area_id, retailers.sub_area_id) 
Left Join users on users.id = retailers.user_id
LEFT JOIN user_types ON user_types.id = retailers.user_type


WHERE users.deleted_at IS NULL
AND retailers.spot_type = FALSE
AND users.is_active = TRUE
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14

--AND CAST(users.created_at + Interval '5HRS' AS DATE) >= '2022-07-01'

),
orders1 AS 
(SELECT 
CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE) AS "Order Cycle Date",
orders.master_order_id,
orders.retailer_id AS "Customer ID",
SUM(order_skus.delivered_qty * order_skus.price) AS "NMV"
--LAG(CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE)) OVER(PARTITION BY orders.retailer_id ORDER BY orders.master_order_id) AS "Last Delivered Order Cycle Date"


FROM order_user_details_fmcg AS orders
LEFT JOIN order_sku_details_fmcg AS order_skus ON order_skus.order_id = orders.order_id

WHERE orders.vertical_id = 1
AND orders.order_status_id IN (4,5)
AND CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE) >= '2023-01-01'
GROUP BY 1,2,3 
),
metrics AS (
SELECT 
orders.retailer_id AS "Customer ID",
MAX(orders.nth_order) AS "Lifetime Orders",
MIN(CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE)) AS "First Order Cycle Date",
MAX(CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE)) AS "Last Order Cycle Date",
(CAST(NOW() AS DATE) - MIN(CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE)))/30 :: FLOAT AS "Customer Age (Months)",
STRING_AGG(DISTINCT order_skus.category, ', ') AS "Categories",
SUM(order_skus.ordered_qty * order_skus.price)/NULLIF(COUNT(DISTINCT orders.master_order_id),0) AS "AOV",
COUNT(DISTINCT orders.master_order_id) AS "Number of Orders",
SUM(order_skus.ordered_qty * order_skus.price) AS "GMV",
MIN(order_skus.ordered_qty * order_skus.price) AS "Min GMV",
MAX(order_skus.ordered_qty * order_skus.price) AS "Max GMV",
NULLIF(SUM(CASE WHEN order_skus.category IN ('Anaaj','Oil and Ghee') THEN (order_skus.ordered_qty * order_skus.price) END),0) AS "A&OG GMV",
NULLIF(SUM(CASE WHEN order_skus.category IN ('Dairy','Beverages') THEN (order_skus.ordered_qty * order_skus.price) END),0) AS "D&B",
NULLIF(SUM(CASE WHEN order_skus.category NOT IN ('Dairy','Beverages','Anaaj','Oil and Ghee') THEN (order_skus.ordered_qty * order_skus.price) END),0) AS "Other GMV",


(NULLIF(SUM(CASE WHEN order_skus.category IN ('Anaaj','Oil and Ghee') THEN (order_skus.ordered_qty * order_skus.price) END),0)
                                        /
    SUM(order_skus.ordered_qty * order_skus.price)) AS "Anaaj Oil Ghee GMV %",
(NULLIF(SUM(CASE WHEN order_skus.category IN ('Dairy','Beverages') THEN (order_skus.ordered_qty * order_skus.price) END),0)
                                        /
    SUM(order_skus.ordered_qty * order_skus.price)) AS "Dairy & Beverages GMV %",
(NULLIF(SUM(CASE WHEN order_skus.category NOT IN ('Dairy','Beverages','Anaaj','Oil and Ghee') THEN (order_skus.ordered_qty * order_skus.price) END),0)
                                        /
    SUM(order_skus.ordered_qty * order_skus.price)) AS "Other Categories GMV %",
    
    
SUM(order_skus.delivered_qty * order_skus.price) AS "NMV",
COUNT(DISTINCT CASE WHEN orders.order_agent_id IS NULL THEN orders.master_order_id END) AS "Direct Orders",
COUNT(DISTINCT CASE WHEN orders.order_agent_id IS NOT NULL THEN orders.master_order_id END) AS "Assisted Orders"


FROM order_user_details_fmcg AS orders
LEFT JOIN order_sku_details_fmcg AS order_skus ON order_skus.order_id = orders.order_id
WHERE orders.vertical_id = 1
AND orders.order_status_id IN (4,5)
AND CAST(orders.order_created_at - INTERVAL '15HRS' AS DATE) >= '2023-01-01'
GROUP BY 1

),
Churn_estimation AS (

SELECT customers.*, 
"First Order Cycle Date", "Last Order Cycle Date", "Categories", "Lifetime Orders", NULLIF("Anaaj Oil Ghee GMV %",0) AS "Anaaj Oil Ghee GMV %", NULLIF("Dairy & Beverages GMV %",0) AS "Dairy & Beverages GMV %",
NULLIF("Other Categories GMV %",0) AS "Other Categories GMV %",

"Number of Orders", "Assisted Orders"/NULLIF("Number of Orders",0) :: FLOAT AS "Assisted Orders %", "Direct Orders"/NULLIF("Number of Orders",0) :: FLOAT AS "Direct Orders %","Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT AS "AOF", 

"AOV", "GMV", "NMV",
CASE WHEN "Customer Age (Months)" < 12 THEN ("Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT)*"AOV"*12 ELSE ("Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT)*"AOV"*"Customer Age (Months)" END AS "Customer Lifetime Value",

"Customer Age"/NULLIF("Number of Orders",0) ::FLOAT AS "Avg Reordering Period",
CAST(NOW() AS DATE) - "Last Order Cycle Date" AS "Days Since Last Order",

case 
when CAST(NOW() AS DATE) - "Last Order Cycle Date" <= 30 then 1
when CAST(NOW() AS DATE) - "Last Order Cycle Date" > 30 and CAST(NOW() AS DATE) - "Last Order Cycle Date" <= 90 then 2
when CAST(NOW() AS DATE) - "Last Order Cycle Date" > 90 then 3
end AS "Recency Score",

Case
when "Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT >= 4 then 1
when "Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT >= 1 and "Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT < 4 then 2
when "Number of Orders"/NULLIF("Customer Age (Months)",0)::FLOAT < 1 then 3
end AS "Frequency Score",

CASE 
WHEN "AOV" >= 200000 THEN 1
WHEN "AOV" >= 50000 AND "AOV" < 200000 THEN 2
WHEN "AOV" >= 25000 AND "AOV" < 50000 THEN 3
WHEN "AOV" >= 7500  AND "AOV" < 25000 THEN 4
WHEN "AOV" < 7500 THEN 5 
END AS "Monetary Score"


FROM customers
LEFT JOIN metrics ON metrics."Customer ID" = customers."Customer ID"
),

gmv_90 AS 
(
  SELECT 
  "Customer ID", 
  MAX("NMV") AS "Max NMV 90" 
FROM orders1  
WHERE "Order Cycle Date" >= CURRENT_DATE - INTERVAL '90' DAY 

GROUP BY 1 
)

SELECT Churn_estimation.*,
CONCAT("Recency Score","Frequency Score","Monetary Score") AS "RFM", "Max NMV 90" AS "MOV-90Day",
(case 
when "Lifetime Orders" IS NULL THEN 'To be Activated' 
When "Lifetime Orders" <= 1  THEN 'To be Graduated' 
When "Lifetime Orders" >= 2 AND CONCAT("Recency Score","Frequency Score","Monetary Score") IN ('112','111') THEN 'Champion'
When "Lifetime Orders" >= 2 AND CONCAT("Recency Score","Frequency Score","Monetary Score") IN ('112','113','114') THEN 'Loyalist'
When "Lifetime Orders" >= 2 AND CONCAT("Recency Score","Frequency Score","Monetary Score") IN ('121','122','123','124') THEN 'Potential Loyalist'
When "Lifetime Orders" >= 2 AND CONCAT("Recency Score","Frequency Score","Monetary Score") IN ('131','132','133','134') THEN 'Promising' 
When "Lifetime Orders" >= 2 AND CONCAT("Recency Score","Frequency Score","Monetary Score") IN ('311','312','313','314','321','322','323','324','331','332','333','334','211','212','213','214','221','222','223','224','231','232','233','234') THEN 'Reactivations'
When "Monetary Score" = 5 THEN 'Low Value'
END) AS "RFM Segmentation",

(CASE 
when "Lifetime Orders" IS NULL THEN 'Acquistion Ops' 
when "Lifetime Orders" <= 1 THEN 'Acquistion Ops'
when "Max NMV 90" >= 200000 AND "Recency Score" IN (1,2) THEN 'Assisted (Field)'
when "Max NMV 90" >= 25000 AND "Max NMV 90" < 50000 AND "Recency Score" IN (1,2) AND "Direct Orders %" < 0.75 THEN 'Assisted (Telesales)'
when "Max NMV 90" >= 50000  AND "Max NMV 90" < 200000 AND "Recency Score" IN (1,2) THEN 'Assisted (Field)'
when "Max NMV 90" >= 7500 AND "Max NMV 90" < 25000 AND "Recency Score" IN (1,2) AND "Direct Orders %" < 0.75 THEN 'Assisted (Telesales)'
ELSE 'Direct Team'
END) AS "Assignment Type" 


FROM Churn_estimation
LEFT JOIN gmv_90 ON Churn_estimation."Customer ID" = gmv_90."Customer ID"
WHERE "Last Order Date" >= '2023-01-01'
OR ("Last Order Date" IS NULL AND "Signup Date" >= '2023-07-01')