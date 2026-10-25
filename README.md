# 📦 Zepto Inventory Data Analysis (SQL Project)

## 🔹 Project Overview
This project focuses on **inventory data exploration and business insights** using MySQL.  
The dataset is inspired by **Zepto’s online grocery platform**, containing details about product categories, pricing, discounts, stock availability, and weights.  

The goal is to **clean, explore, and analyze** the dataset to derive actionable business insights such as:
- Top discounted products
- Revenue estimation by category
- Out-of-stock high-value products
- Value-for-money comparisons
- Weight-based product categorization  

---

## 📂 Dataset
- File: `zepto_inventory.csv`
- Size: ~3,600+ SKUs  
- Columns:
  - `category` – Product category (e.g., Beverages, Snacks, Dairy)  
  - `name` – Product name  
  - `mrp` – Maximum retail price (₹)  
  - `discountpercent` – Discount percentage offered  
  - `availableQuantity` – Units in stock  
  - `discountedsellingprice` – Final selling price (₹)  
  - `weightingms` – Product weight in grams  
  - `outofstock` – TRUE/FALSE flag  
  - `quantity` – Pack quantity  

---

## 🔍 SQL Exploration & Cleaning
Key steps performed:
1. **Data Exploration**
   - Count rows, null checks, distinct categories  
   - Detect duplicate product names  
2. **Data Cleaning**
   - Removed products with invalid price (`mrp = 0`)  
   - Converted paise → rupees  
   - Added **primary key** (`Sku_Id`)  
3. **Business Queries**
   - Top 10 products by discount  
   - Out-of-stock premium products  
   - Estimated revenue per category  
   - Price-per-gram analysis  
   - Categorization into **Low / Medium / Bulk** by weight  

---

## 📊 Sample Business Insights
- **Top 10 Discounts** → Products offering up to 70% discount  
- **Revenue Contribution** → Beverages & Packaged Food dominate inventory revenue  
- **Premium Out-of-Stock Products** → High MRP (>₹500) items frequently run out  
- **Best Value** → Large pack items (bulk) have lowest price per gram  

---

## 💡 Example Business Query: Categorization by Weight  

One of the business needs is to categorize products into **Low, Medium, and Bulk weight categories**.  
There are multiple approaches in SQL to handle this:

### 1️⃣ Simple Rule-Based Categorization
This uses fixed thresholds (easy to understand, widely used):  

`sql
SELECT DISTINCT 
       name, 
       weightingms, 
       CASE 
           WHEN weightingms < 1000 THEN 'Low'
           WHEN weightingms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_category
FROM zepto_inventory;`

### 2️⃣ Dynamic Categorization Based on Data Distribution
This approach calculates thresholds from dataset statistics (min, avg, max) so the categorization adjusts automatically if data changes.
```sql
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

