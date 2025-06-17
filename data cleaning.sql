select * from customers_data;
select * from discount_coupon;
select * from marketing_spend;
select * from online_sales;
select * from tax_amount;


-- Fix Date Format in marketing_spend Table . 
-- Converted Date (string) to proper DATE type. Ensures compatibility for time-based analysis.
ALTER TABLE marketing_spend
ADD COLUMN Date_converted DATE;
SET SQL_SAFE_UPDATES = 0;

UPDATE marketing_spend
SET Date_converted = STR_TO_DATE(Date, '%m/%d/%Y');

ALTER TABLE marketing_spend
DROP COLUMN Date;

ALTER TABLE marketing_spend
CHANGE COLUMN Date_converted Date DATE;


-- Fix Date Format in online_sales Table.
-- Standardized transaction_Date for consistent querying and joins.
UPDATE online_sales 
SET transaction_Date = STR_TO_DATE(transaction_Date, '%m/%d/%Y');

ALTER TABLE online_sales
MODIFY COLUMN Transaction_Date DATE;



-- Clean and Convert GST in tax_amount Table.
-- Removed % signs, handled invalid GST entries, and changed data type from TEXT to INT.
UPDATE tax_amount 
SET GST = TRIM(TRAILING '%' FROM GST) 
WHERE GST LIKE '%';

UPDATE tax_amount 
SET GST = NULL 
WHERE GST REGEXP '[^0-9]';

ALTER TABLE tax_amount MODIFY COLUMN GST INT;

-- Standardize Month Values in discount_coupon Table.
-- Converted month names to numbers for easier filtering and joins on date. 
    SET SQL_SAFE_UPDATES = 0;

UPDATE discount_coupon
SET Month = CASE 
    WHEN Month = 'Jan' THEN 1
    WHEN Month = 'Feb' THEN 2
    WHEN Month = 'Mar' THEN 3
    WHEN Month = 'Apr' THEN 4
    WHEN Month = 'May' THEN 5
    WHEN Month = 'Jun' THEN 6
    WHEN Month = 'Jul' THEN 7
    WHEN Month = 'Aug' THEN 8
    WHEN Month = 'Sep' THEN 9
    WHEN Month = 'Oct' THEN 10
    WHEN Month = 'Nov' THEN 11
    WHEN Month = 'Dec' THEN 12
END;



-- changing datatype of month 
ALTER TABLE discount_coupon 
MODIFY COLUMN Month tinyint;


-- Create Consolidated View: merged_tables.
-- Unified data from multiple sources, calculated post-discount and tax-adjusted Invoice_Amt, and made future queries cleaner via a reusable view.
DROP VIEW IF EXISTS merged_tables;

CREATE VIEW merged_tables AS 
SELECT 
    o.Transaction_ID,
    o.CustomerID,
    c.Location, 
    c.gender,
    c.Tenure_Months, -- Adding Location & Customer Info
    o.Transaction_Date,
    o.Product_Category,
    o.Quantity,
    o.Avg_Price,
    o.Delivery_Charges,
    d.discount_pct AS Discount_Percentage,
    t.gst AS GST_Percentage,
    ROUND(
        (o.Quantity * o.Avg_Price) 
        * (1 - COALESCE(d.discount_pct, 0) / 100)  -- Apply discount
        * (1 + COALESCE(t.gst, 0) / 100)  -- Apply GST
        + o.Delivery_Charges, 2
    ) AS Invoice_Amt  
FROM online_sales o
LEFT JOIN customersdata c 
    ON o.CustomerID = c.CustmerID  
LEFT JOIN discount_coupon d 
    ON o.Product_Category = d.Product_Category 
    AND EXTRACT(MONTH FROM o.Transaction_Date) = d.Month  
LEFT JOIN tax_amount t 
    ON t.Product_Category = o.Product_Category;

SELECT * FROM merged_tables;












