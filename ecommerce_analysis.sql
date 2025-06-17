-- ============================================================
-- E-COMMERCE ANALYTICS | SQL-BASED KPI & INSIGHT GENERATION
-- ============================================================


-- ================================
-- 1. Invoice Amount (Sale Revenue)
-- ================================

-- Invoice Value = ((Quantity * Avg_price) * (1 - Discount_pct) * (1 + GST)) + Delivery_Charges

SELECT 
    transaction_id,
    product_category,
    ROUND(SUM(invoice_amt), 2) AS total_sale_amount 
FROM 
    merged_tables
GROUP BY 
    product_category, transaction_id;


-- =========================
-- 2. Average Order Value (AOV)
-- =========================

SELECT 
    ROUND(SUM(Invoice_Amt) / COUNT(DISTINCT Transaction_ID), 2) AS AOV
FROM 
    merged_tables;


-- ===================
-- 3. Profit Margin (%)
-- ===================

WITH expenses AS (
    SELECT 
        ROUND(SUM(Online_Spend), 2) + ROUND(SUM(Offline_Spend), 2) AS total_expense
    FROM Marketing_Spend
)
SELECT 
    CONCAT(
        ROUND((SUM(m.Invoice_Amt) - MAX(e.total_expense)) / SUM(m.Invoice_Amt) * 100, 2), '%'
    ) AS profit_margin
FROM merged_tables m
JOIN expenses e ON 1 = 1;


-- ======================
-- 4. Purchase Frequency
-- ======================

SELECT 
    COUNT(DISTINCT CustomerID) AS total_cust,
    COUNT(Transaction_ID) AS total_transaction,
    ROUND(COUNT(Transaction_ID) / COUNT(DISTINCT CustomerID), 2) AS purchase_frequency
FROM 
    online_sales;


-- ==============================================
-- 5. Repeat Rate & Churn Rate (Month-to-Month)
-- ==============================================

WITH customer_months AS (
    SELECT 
        CustomerID, 
        COUNT(DISTINCT DATE_FORMAT(Transaction_Date, '%Y-%m')) AS active_months
    FROM merged_tables
    GROUP BY CustomerID
),
repeat_rate AS (
    SELECT 
        ROUND((COUNT(CASE WHEN active_months > 1 THEN 1 END) * 100.0) / COUNT(*), 2) AS repeat_rate
    FROM customer_months
),
churn_rate AS (
    SELECT 
        ROUND((COUNT(DISTINCT first_half.CustomerID) - COUNT(DISTINCT second_half.CustomerID)) 
        * 100.0 / COUNT(DISTINCT first_half.CustomerID), 2) AS churn_rate
    FROM (
        SELECT DISTINCT CustomerID 
        FROM merged_tables 
        WHERE MONTH(Transaction_Date) BETWEEN 1 AND 6
    ) first_half
    LEFT JOIN (
        SELECT DISTINCT CustomerID 
        FROM merged_tables 
        WHERE MONTH(Transaction_Date) BETWEEN 7 AND 12
    ) second_half
    ON first_half.CustomerID = second_half.CustomerID
)
SELECT 
    r.repeat_rate, 
    c.churn_rate
FROM 
    repeat_rate r
JOIN 
    churn_rate c;


-- ================================
-- 6. Customer Lifetime Value (CLTV)
-- ================================

WITH sales_summary AS (
    SELECT 
        COUNT(DISTINCT CustomerID) AS total_customers,
        COUNT(Transaction_ID) AS total_transactions,
        SUM(invoice_Amt) AS total_revenue,
        AVG(Tenure_Months) / 12 AS avg_tenure
    FROM merged_tables
)
SELECT 
    ROUND(
        (total_revenue / total_customers) 
        * (total_transactions / total_customers) 
        * avg_tenure, 
    2) AS CLTV
FROM 
    sales_summary;


-- ==================================================
-- 7. Monthly Unique Active Customers (Not New/Repeat)
-- ==================================================

SELECT 
    MONTH(Transaction_Date) AS Month, 
    COUNT(DISTINCT CustomerID) AS Customer_Count
FROM 
    online_sales
GROUP BY 
    MONTH(Transaction_Date)
ORDER BY 
    MONTH(Transaction_Date);


-- ===================================================
-- 8. Monthly Retained Customers by Tenure Bucket
-- ===================================================

SELECT 
    MONTH(o.Transaction_Date) AS Month, 
    c.Tenure_Months,
    COUNT(o.CustomerID) AS No_of_Cust_Retained
FROM 
    online_sales o
JOIN 
    CustomersData c ON o.CustomerID = c.CustmerID
GROUP BY 
    MONTH(o.Transaction_Date), c.Tenure_Months
ORDER BY 
    MONTH(o.Transaction_Date), c.Tenure_Months;


-- ================================================
-- 9. Top 5 Product Categories by Quantity Sold
-- ================================================

SELECT 
    Product_Category,
    SUM(Quantity) AS Total_Quantity
FROM 
    online_sales
GROUP BY 
    Product_Category
ORDER BY 
    Total_Quantity DESC
LIMIT 5;


-- ========================================================
-- 10. Month-over-Month Customer Retention Rate (Rolling)
-- ========================================================

SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

SELECT 
    DATE_FORMAT(o1.transaction_date, '%Y-%m') AS Current_Month,
    COUNT(DISTINCT o1.customerID) AS Total_Customers,
    COUNT(DISTINCT o2.customerID) AS Retained_Customers,
    ROUND(
        IFNULL((COUNT(DISTINCT o2.customerID) / NULLIF(COUNT(DISTINCT o1.customerID), 0)) * 100, 0), 
    2) AS Retention_Rate
FROM 
    online_sales o1
LEFT JOIN 
    online_sales o2 
    ON o1.customerID = o2.customerID
    AND DATE_FORMAT(o2.transaction_date, '%Y-%m') = DATE_FORMAT(DATE_ADD(o1.transaction_date, INTERVAL 1 MONTH), '%Y-%m')
GROUP BY 
    DATE_FORMAT(o1.transaction_date, '%Y-%m')
ORDER BY 
    Current_Month;

-- =========================================================
-- 11. KPI Breakdown by Category, Month, Week, and Day
-- =========================================================

-- By Product Category
SELECT 
    Product_Category,
    COUNT(DISTINCT Transaction_ID) AS Total_Orders,
    ROUND(SUM(invoice_Amt), 2) AS Total_Revenue,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(invoice_Amt) / NULLIF(COUNT(DISTINCT Transaction_ID), 0), 2) AS Avg_Order_Value,
    COUNT(DISTINCT CustomerID) AS Total_Customers
FROM 
    merged_tables 
GROUP BY 
    Product_Category;

-- By Month
SELECT 
    DATE_FORMAT(Transaction_Date, '%Y-%m') AS YearMonth,
    COUNT(DISTINCT Transaction_ID) AS Total_Orders,
    ROUND(SUM(invoice_Amt), 2) AS Total_Revenue,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(invoice_Amt) / NULLIF(COUNT(DISTINCT Transaction_ID), 0), 2) AS Avg_Order_Value,
    COUNT(DISTINCT CustomerID) AS Total_Customers
FROM 
    merged_tables 
GROUP BY 
    YearMonth
ORDER BY 
    YearMonth;

-- By Week
SELECT 
    WEEK(Transaction_Date, 3) AS Week_Number,
    COUNT(DISTINCT Transaction_ID) AS Total_Orders,
    ROUND(SUM(invoice_Amt), 2) AS Total_Revenue,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(invoice_Amt) / NULLIF(COUNT(DISTINCT Transaction_ID), 0), 2) AS Avg_Order_Value,
    COUNT(DISTINCT CustomerID) AS Total_Customers
FROM 
    merged_tables 
GROUP BY 
    Week_Number
ORDER BY 
    Week_Number;

-- By Day
SELECT 
    transaction_date,
    COUNT(DISTINCT Transaction_ID) AS Total_Orders,
    ROUND(SUM(invoice_Amt), 2) AS Total_Revenue,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(invoice_Amt) / NULLIF(COUNT(DISTINCT Transaction_ID), 0), 2) AS Avg_Order_Value,
    COUNT(DISTINCT CustomerID) AS Total_Customers
FROM 
    merged_tables 
GROUP BY 
    transaction_date;


-- =========================================================
-- 12. Revenue by Customer Type: New vs Existing (Month-wise)
-- =========================================================

WITH first_purchase AS (
    SELECT 
        customerid, 
        MIN(Transaction_Date) AS first_purchase_date
    FROM 
        merged_tables
    GROUP BY 
        customerid
),
categorized_revenue AS (
    SELECT 
        DATE_FORMAT(m.Transaction_Date, '%Y-%m') AS month,
        m.customerid,
        SUM(m.invoice_amt) AS revenue,
        CASE 
            WHEN DATE_FORMAT(m.Transaction_Date, '%Y-%m') = DATE_FORMAT(f.first_purchase_date, '%Y-%m') 
            THEN 'New' ELSE 'Existing' 
        END AS customer_type
    FROM 
        merged_tables m
    JOIN 
        first_purchase f ON m.customerid = f.customerid
    GROUP BY 
        month, m.customerid, customer_type
)
SELECT 
    month,
    ROUND(SUM(CASE WHEN customer_type = 'New' THEN revenue ELSE 0 END), 2) AS new_customer_revenue,
    ROUND(SUM(CASE WHEN customer_type = 'Existing' THEN revenue ELSE 0 END), 2) AS existing_customer_revenue,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM 
    categorized_revenue
GROUP BY 
    month
ORDER BY 
    month;


-- =========================================================
-- 13. Discount Effect on Revenue
-- =========================================================

SELECT 
    MONTH(Transaction_Date) AS Month,
    Product_Category,
    ROUND(SUM(Invoice_Amt), 2) AS Total_Revenue,
    ROUND(SUM(Quantity * Avg_Price), 2) AS Revenue_Without_Discount,
    ROUND(SUM(Quantity * Avg_Price * (1 - (IFNULL(Discount_Percentage, 0) / 100))), 2) AS Revenue_After_Discount,
    CONCAT(
        ROUND(
            (SUM(Quantity * Avg_Price * (1 - (IFNULL(Discount_Percentage, 0) / 100))) 
             / SUM(Quantity * Avg_Price)) * 100, 
        2), '%'
    ) AS Revenue_Percentage_After_Discount
FROM 
    merged_tables
GROUP BY 
    MONTH(Transaction_Date), Product_Category
ORDER BY 
    MONTH(Transaction_Date), Product_Category;


-- =========================================================
-- 14. Seasonal Trends by Category and Location
-- =========================================================

-- Overall
SELECT 
    DATE_FORMAT(Transaction_Date, '%Y-%m') AS Sales_Month,
    product_Category AS Category,
    Location,
    COUNT(DISTINCT Transaction_ID) AS Total_Orders,
    ROUND(SUM(Invoice_Amt), 2) AS Total_Revenue
FROM 
    merged_tables
GROUP BY 
    DATE_FORMAT(Transaction_Date, '%Y-%m'), product_Category, Location
ORDER BY 
    DATE_FORMAT(Transaction_Date, '%Y-%m');

-- Top 5 Categories by Sales Per Month
WITH CategoryRank AS (
    SELECT 
        DATE_FORMAT(Transaction_Date, '%Y-%m') AS Sales_Month,
        product_Category,
        ROUND(SUM(Invoice_Amt), 2) AS Total_Revenue,
        COUNT(DISTINCT Transaction_ID) AS Total_Orders,
        RANK() OVER (PARTITION BY DATE_FORMAT(Transaction_Date, '%Y-%m') ORDER BY SUM(Invoice_Amt) DESC) AS Sales_Rank
    FROM 
        merged_tables
    GROUP BY 
        Sales_Month, product_Category
)
SELECT 
    Sales_Month,
    product_Category,
    Total_Revenue,
    Total_Orders,
    Sales_Rank
FROM 
    CategoryRank
WHERE 
    Sales_Rank <= 5
ORDER BY 
    Sales_Month, Sales_Rank;


-- =========================================================
-- 15. Peak Sales Months (Top 3)
-- =========================================================

SELECT 
    MONTH(Transaction_Date) AS Month,
    ROUND(SUM(Invoice_Amt), 2) AS Total_Sales
FROM 
    merged_tables
GROUP BY 
    MONTH(Transaction_Date)
ORDER BY 
    Total_Sales DESC
LIMIT 3;


-- =========================================================
-- 16. Month-over-Month (MoM) Growth Trend
-- =========================================================

WITH Monthly_Sales AS (
    SELECT 
        DATE_FORMAT(Transaction_Date, '%Y-%m') AS month,
        ROUND(SUM(Invoice_Amt), 2) AS total_sales
    FROM 
        merged_tables
    GROUP BY 
        DATE_FORMAT(Transaction_Date, '%Y-%m')
),
MoM_Trend AS (
    SELECT 
        month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY month) AS prev_month_sales,
        ROUND(
            ((total_sales - LAG(total_sales) OVER (ORDER BY month)) / 
            NULLIF(LAG(total_sales) OVER (ORDER BY month), 0)) * 100, 2
        ) AS MoM_Growth
    FROM 
        Monthly_Sales
)
SELECT * FROM MoM_Trend;


-- =========================================================
-- 17. Order & Sales Distribution by Day of Week
-- =========================================================

SELECT 
    DAYNAME(Transaction_Date) AS day_of_week,
    COUNT(DISTINCT Transaction_ID) AS total_orders,
    ROUND(SUM(Invoice_Amt), 2) AS total_sales
FROM 
    merged_tables
GROUP BY 
    day_of_week
ORDER BY 
    FIELD(day_of_week, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');


-- =========================================================
-- 18. Revenue vs Marketing Spend + Tax + Delivery Charges
-- =========================================================
WITH Marketing_Spend_Corrected AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS Sales_Month,  
        ROUND(SUM(Offline_Spend + Online_Spend), 2) AS Total_Marketing_Spend  
    FROM marketing_spend
    GROUP BY DATE_FORMAT(date, '%Y-%m')
)

SELECT 
    DATE_FORMAT(mt.Transaction_Date, '%Y-%m') AS Sales_Month,  
    ROUND(SUM(mt.Invoice_Amt), 2) AS Total_Revenue,  
    m.Total_Marketing_Spend,  
    ROUND(SUM(mt.Quantity * mt.Avg_Price * (mt.GST_Percentage / 100)), 2) AS Total_Tax_Amount,  
    ROUND(SUM(mt.Delivery_Charges), 2) AS Total_Delivery_Charges  
FROM 
    merged_tables mt
LEFT JOIN Marketing_Spend_Corrected m  
    ON DATE_FORMAT(mt.Transaction_Date, '%Y-%m') = m.Sales_Month  
GROUP BY 
    DATE_FORMAT(mt.Transaction_Date, '%Y-%m'), m.Total_Marketing_Spend  
ORDER BY 
    DATE_FORMAT(mt.Transaction_Date, '%Y-%m');


-- =========================================================
-- 19. Revenue-to-Marketing Spend Ratio by Month
-- =========================================================

WITH Marketing_Spend_Corrected AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS Sales_Month,
        SUM(Offline_Spend + Online_Spend) AS Total_Marketing_Spend
    FROM 
        marketing_spend
    GROUP BY 
        Sales_Month
)
SELECT 
    m.Sales_Month, 
    ROUND(SUM(mt.Invoice_Amt), 2) AS Total_Revenue, 
    ROUND(m.Total_Marketing_Spend, 2) AS total_marketing_spend, 
    ROUND(SUM(mt.Invoice_Amt) / NULLIF(m.Total_Marketing_Spend, 0), 2) AS Revenue_to_Spend_Ratio
FROM 
    merged_tables mt
JOIN 
    Marketing_Spend_Corrected m 
    ON DATE_FORMAT(mt.Transaction_Date, '%Y-%m') = m.Sales_Month
GROUP BY 
    m.Sales_Month, m.Total_Marketing_Spend
ORDER BY 
    m.Sales_Month;


-- ================================================
-- 20. RFM SEGMENTATION: Recency, Frequency, Monetary
-- ================================================

-- This query segments customers based on:
-- - Recency: How recently they purchased
-- - Frequency: How often they purchase
-- - Monetary: How much they spend

WITH customer_metrics AS (
    SELECT 
        CustomerID,
        MAX(Transaction_Date) AS last_purchase_date,
        COUNT(Transaction_ID) AS frequency,
        ROUND(SUM(Invoice_Amt), 2) AS monetary
    FROM merged_tables
    GROUP BY CustomerID
),
recency_calc AS (
    SELECT 
        *,
        DATEDIFF(
            (SELECT MAX(Transaction_Date) FROM merged_tables), 
            last_purchase_date
        ) AS recency
    FROM customer_metrics
)
SELECT 
    CustomerID,
    recency,
    frequency,
    monetary,
    CASE 
        WHEN recency <= 30 AND frequency >= 3 AND monetary >= 5000 THEN 'Champion'
        WHEN recency <= 60 AND frequency >= 2 THEN 'Loyal'
        WHEN recency BETWEEN 61 AND 120 THEN 'At Risk'
        WHEN recency > 120 THEN 'Churn Risk'
        ELSE 'New/Undefined'
    END AS customer_segment
FROM recency_calc
ORDER BY recency;


-- =========================================================
-- 21. Monthly Profitability Analysis
-- =========================================================
-- Calculates net profit = Revenue - (Marketing Spend + Tax + Delivery)

WITH Monthly_Revenue AS (
    SELECT 
        DATE_FORMAT(Transaction_Date, '%Y-%m') AS Sales_Month,
        ROUND(SUM(Invoice_Amt), 2) AS Revenue,
        ROUND(SUM(Quantity * Avg_Price * (GST_Percentage / 100)), 2) AS Tax_Amount,
        ROUND(SUM(Delivery_Charges), 2) AS Delivery_Charges
    FROM merged_tables
    GROUP BY Sales_Month
),

Monthly_Marketing AS (
    SELECT 
        DATE_FORMAT(CAST(Date AS DATE), '%Y-%m') AS Sales_Month,
        ROUND(SUM(Offline_Spend + Online_Spend), 2) AS Marketing_Spend
    FROM marketing_spend
    GROUP BY Sales_Month
)

SELECT 
    r.Sales_Month,
    r.Revenue,
    m.Marketing_Spend,
    r.Tax_Amount,
    r.Delivery_Charges,
    ROUND(
        r.Revenue - IFNULL(m.Marketing_Spend, 0) - r.Tax_Amount - r.Delivery_Charges,
        2
    ) AS Net_Profit
FROM Monthly_Revenue r
LEFT JOIN Monthly_Marketing m ON r.Sales_Month = m.Sales_Month
ORDER BY r.Sales_Month;
