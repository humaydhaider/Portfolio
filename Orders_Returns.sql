--- Customer returns and return rate by Customer_ID


Select Customer_id, order_date, quantity from Orders$;
Select * from Returns$;

Select 
	DISTINCT o.customer_Id AS Customer_ID, 
	COUNT(r.returned) AS 'Total Returned Orders', 
	CONCAT(100*COUNT(r.returned) / COUNT(o.Order_ID),'%') AS 'Return Rate'
From Orders$ o
INNER JOIN
Returns$ r ON o.Order_ID = r.Order_ID
Group by o.Customer_ID, r.Returned;


--- Managers' profitability, divided monthly

Select * from Managers$;
Select region, profit from Orders$;

Select 
	DATENAME(Month,Order_date) AS Month,
	m.person AS Manager,
	SUM(Profit) AS Profit_Loss
From Managers$ m
JOIN
Orders$ o ON m.Region = o.Region
Group by Month, Manager
Order by Month ASC;

--- Difference between order and shipping date.
--- Percentage of orders delivered within 2 days

Select * from Orders$;

Select 
	DATENAME(Month,Order_Date) AS Month, 
	AVG(DATEDIFF(Day,Order_Date,Ship_Date)) AS Order_to_Ship,
	CONCAT(100*COUNT(Case when DATEDIFF(Day,Order_Date,Ship_Date) <= 2 then Order_ID else null end) / (Count(Order_Id)),'%') AS '% orders shipped in 2 days'
	From Orders$
	Group by Month
	Order by Month ASC;
	

--- Ranking top 5 selling products by month.

Select Product_Name, Month1, Total_Qty from
	(Select
	 Product_Name,
	 DATENAME(month,order_date) AS Month1, 
	 SUM(Quantity) As Total_Qty,
	 RANK() OVER (Partition by DATENAME(month,order_date) Order by SUM(Quantity) DESC) AS 'Rank1'
From 
	 Orders$
Group by 
	 Product_name, 
	 DATENAME(month,order_date))
	 
A Where Rank1 Between 1 AND 5
Group by 
	Product_Name,
	Month1, 
	Total_Qty;














