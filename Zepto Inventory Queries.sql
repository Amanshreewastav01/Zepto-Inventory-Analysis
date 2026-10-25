Create Database Zepto_Inventory_Dataset;

Use Zepto_Inventory_Dataset;

/* Data Exploration */

# Sample Data 
Select * From zepto_inventory;

# Count Of Raws
Select Count(*) From zepto_inventory;

# Count of Null Values
Select * From zepto_inventory
Where 
category is null OR
name is null OR
mrp is null OR
discountpercent is null OR
availableQuantity is null OR
discountedsellingprice is null OR
weightingms is null OR
outofstock is null OR
quantity is null;

# Different Product Categories
Select Distinct category From zepto_inventory
Group By category
Order By Category Asc;

# Different Product Categories by Serial Numbers
Select
      row_number() Over (Order By Category) As SN, Category
From zepto_inventory
Where Category is not null
Group By Category
Order By Category Asc;

# Product in Stock vs Outofstock (Before need to Check/create PK for absolute count)
#Checking PK
SHOW KEYS FROM zepto_inventory WHERE Key_name = 'PRIMARY';

/* Let's Create PK */
ALTER TABLE zepto_inventory
ADD COLUMN Sku_Id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

SELECT outofstock, Count(Sku_ID) AS Total_items
FROM zepto_inventory
GROUP BY outofstock;

# Product Name Presented Multiple times
SELECT name, COUNT(Sku_Id) AS Number_of_SKUs
FROM zepto_inventory
GROUP BY name
HAVING Count(Sku_Id) > 1
ORDER BY COUNT(Sku_Id) DESC;

#Data Cleaning 
/* Product Having Price = 0 */
SELECT * FROM zepto_inventory
WHERE mrp = 0 AND discountedsellingprice = 0;

DELETE FROM zepto_inventory
WHERE Sku_Id = 3666;

/* Convert Paise to Rupees */
SET SQL_SAFE_UPDATES = 0;

UPDATE zepto_inventory
SET mrp = mrp/100,
discountedsellingprice = discountedsellingprice/100;

SELECT mrp,discountedsellingprice FROM zepto_inventory;

/* Business Questions */
#1). Which are the top 10 best-value products based on discount percentage?

#Basic Syntax
SELECT name,mrp,discountpercent FROM zepto_inventory
ORDER BY discountpercent DESC
LIMIT 10;

#Advance Syntax
SELECT ROW_NUMBER() OVER(ORDER BY discountpercent DESC) AS SN,name,mrp,discountpercent
FROM(
     SELECT name,mrp,discountpercent,
     ROW_NUMBER() OVER(PARTITION BY name ORDER BY discountpercent DESC) AS RN
     FROM zepto_inventory
     WHERE name IS NOT NULL
     ) AS T
WHERE RN = 1
ORDER BY discountpercent DESC
LIMIT 10;

#2). Which high-MRP products are currently out of stock?

SELECT AVG(mrp) FROM zepto_inventory;

SELECT DISTINCT name,mrp
FROM zepto_inventory
WHERE outofstock = "TRUE" AND mrp > 157
ORDER BY mrp DESC;

#3). What is the estimated potential revenue for each product category?

SELECT Category, SUM(discountedsellingprice * availablequantity) AS Total_revenue
FROM zepto_inventory
GROUP BY category
ORDER BY Total_revenue;

#4). Which products hvae (MRP > ₹500) and (Discount < 10%)?

SELECT DISTINCT name, mrp, discountpercent
FROM zepto_inventory
WHERE MRP > 500 AND discountpercent < 10
ORDER BY MRP DESC, discountpercent DESC;

#5). Which are the top 5 categories offering the highest average discounts?

SELECT DISTINCT category, AVG(discountpercent) AS avg_discount
FROM zepto_inventory
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

#6). What is the price per gram for products above 100g, and which ones offer the best value-for-money?

SELECT DISTINCT name, weightingms, discountedsellingprice, ROUND(discountedsellingprice/weightingms,2) AS price_per_grams
FROM zepto_inventory
WHERE weightingms >= 100
ORDER BY price_per_grams;

#7). How can products be grouped into Low, Medium, and Bulk categories based on weight?

/* NOOB */ 
SELECT DISTINCT name, weightingms, 
       CASE WHEN weightingms <1000 THEN 'Low'
	   WHEN weightingms <5000 THEN 'Medium'
       ELSE 'Bulk'
       END AS weight_category
FROM zepto_inventory

/* PRO */

WITH stats AS (
    SELECT 
        MIN(weightingms) AS min_w,
        AVG(weightingms) AS avg_w,
        MAX(weightingms) AS max_w
    FROM zepto_inventory
)
SELECT
    z.name,
    MIN(z.weightingms) AS weightingms,  -- pick one value per product
    ROUND(MAX(s.avg_w) * 3, 2) AS low_threshold,
    ROUND(MAX(s.max_w) / 3, 2) AS medium_threshold,
    CASE
        WHEN MIN(z.weightingms) < (MAX(s.avg_w) * 3) THEN 'Low'
        WHEN MIN(z.weightingms) < (MAX(s.max_w) / 3) THEN 'Medium'
        ELSE 'Bulk'
    END AS weight_category
FROM zepto_inventory z
CROSS JOIN stats s
GROUP BY z.name
ORDER BY weightingms;

#8). What is the total inventory weight for each product category?

SELECT Category, SUM(weightingms + availablequantity) AS total_weight
FROM zepto_inventory
GROUP BY Category
ORDER BY total_weight;
