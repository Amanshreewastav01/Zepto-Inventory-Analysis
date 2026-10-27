# 📦 Zepto Inventory Data Analysis (SQL Project)

## 🔹 Project Overview
This project explores, cleans and analyzes a Zepto-style quick-commerce inventory dataset using **MySQL**. The dataset covers product categories, pricing, discounts, stock availability and weights.

**Business questions answered**
- Which products offer the best discounts?
- Which high-MRP products are out of stock?
- What is the potential revenue by category?
- Which premium products (MRP > ₹500) have low discounts (< 10%)?
- Which categories discount the most on average?
- Which products give the best price per gram?
- How can products be grouped by weight (Low / Medium / Bulk)?
- What is the total inventory weight per category?

---

## 📂 Dataset
- **File:** `zepto_inventory.csv` (loaded into table `zepto_inventory`, database `Zepto_Inventory_Dataset`)
- **Size:** ~3,600 SKUs

| Column | Description |
|---|---|
| `Sku_Id` | Primary key, added during cleaning |
| `category` | Product category |
| `name` | Product name (can repeat across SKUs) |
| `mrp` | Maximum retail price (paise in raw data, ₹ after cleaning) |
| `discountpercent` | Discount percentage offered |
| `availableQuantity` | Units in stock |
| `discountedsellingprice` | Selling price after discount (paise in raw data, ₹ after cleaning) |
| `weightingms` | Product weight in grams |
| `outofstock` | `TRUE` / `FALSE` flag |
| `quantity` | Pack quantity |

---

## 🔍 Exploration & Cleaning
1. **Data exploration**
   - Row count, null checks, distinct categories
   - In-stock vs out-of-stock counts
   - Duplicate product names
2. **Data cleaning**
   - Added a primary key (`Sku_Id`)
   - Removed the record with `mrp = 0` and `discountedsellingprice = 0`
   - Converted prices from paise to rupees (run this `UPDATE` **only once**)

---

## 📊 Business Queries

| # | Question | Approach |
|---|---|---|
| 1 | Top 10 best-value products | Order by `discountpercent`; `ROW_NUMBER()` removes repeated names |
| 2 | High-MRP products out of stock | `outofstock = 'TRUE'` and `mrp` above the average |
| 3 | Potential revenue by category | `SUM(discountedsellingprice * availablequantity)` |
| 4 | Premium, low-discount products | `mrp > 500` and `discountpercent < 10` |
| 5 | Top 5 categories by average discount | `AVG(discountpercent)` per category |
| 6 | Price per gram (≥ 100 g) | `discountedsellingprice / weightingms` |
| 7 | Low / Medium / Bulk weight bands | `CASE` rules, or thresholds from data statistics |
| 8 | Total inventory weight by category | `SUM(weightingms * availablequantity)` |

> **Findings:** add your actual query results here (for example the top discount, leading category by revenue). Figures should come from the output of your own run.

---

## 💡 Example: Categorizing Products by Weight

### 1️⃣ Simple rule-based categorization
Fixed thresholds: easy to read and explain.

```sql
SELECT DISTINCT
       name,
       weightingms,
       CASE
           WHEN weightingms < 1000 THEN 'Low'
           WHEN weightingms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_category
FROM zepto_inventory;
```

### 2️⃣ Dynamic categorization from data distribution
Thresholds are calculated from dataset statistics, so the bands adjust if the data changes.

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
    MIN(z.weightingms) AS weightingms,  -- one value per product
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
```

---

