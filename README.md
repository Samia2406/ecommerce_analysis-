## 📊 E-Commerce Analytics & Marketing Performance Project

A complete end-to-end business analysis project simulating an e-commerce company’s sales, customer behavior, marketing effectiveness, and profitability — built using **SQL** for deep analysis and **Power BI** for dynamic dashboarding.

This self-led project demonstrates end-to-end analytical thinking — from preparing raw datasets to extracting actionable insights using SQL and visualizing business performance through Power BI.

---

### 🧩 Project Components

| File                             | Description |
|----------------------------------|-------------|
| `data_cleaning.sql`              | Cleans and standardizes all raw tables (dates, discounts, GST, etc.) |
| `ecommerce_analysis.sql`         | Contains SQL queries analyzing KPIs, retention, churn, profitability |
| `ecommerce_marketing_dashboard.pbix` | Interactive Power BI dashboard visualizing key insights from SQL |
| `merged_tables` (SQL view)       | Combines cleaned tables into one queryable dataset used across analysis |

---

### 🎯 Business Objectives Covered

- Track key KPIs: Revenue, AOV, CLTV, Profit Margin
- Segment customers using RFM analysis
- Analyze discounting impact on revenue
- Measure customer churn, retention, and repeat rates
- Map marketing spend to revenue and calculate ROI
- Calculate net profit after tax, delivery, and marketing costs
- Identify peak-performing months and categories

---

### 🧽 Data Cleaning Overview

Performed in `data_cleaning.sql`:
- Converted inconsistent date formats (MM/DD/YYYY → DATE)
- Removed symbols like `%` in tax columns
- Converted text-based months (e.g., "Jan") to numeric (e.g., 1)
- Fixed mismatches in key joins (`CustomerID`, `Product_Category`)
- Created a final SQL view `merged_tables` joining all datasets

---

### 💡 Key Insights

| Metric                 | Insight                                                                 
|------------------------|-------------------------------------------------------------------------
| 🔁 Repeat Rate        | ~38% of customers returned for purchases across multiple months         
| 📉 Churn Rate         | ~42% customer drop-off in second half of the year                       
| 💰 Discount Impact    | 14–22% drop in revenue due to aggressive discounting                    
| 📢 Marketing ROI      | Peak month showed 3.5× revenue-to-spend ratio                           
| 💸 Monthly Profitability | Net profit tracked monthly after tax, delivery, and ad costs         

---

### 📊 Power BI Dashboard Features

| Feature               | Description                                                                 
|-----------------------|----------------------------------------------------------------------------
| KPI Cards             | Revenue, Profit Margin, CLTV, Orders, Churn Rate                            
| Drill-through Filters | Explore data by product, category, and customer segments                   
| Slicers               | Filter by month, channel, customer group                                   
| Visuals               | Time-series charts, bar charts, stacked columns                            

---

### 🛠️ Tools & Skills Used

- **SQL(MySQL)**: Joins, aggregations, CTEs, window functions, KPI calculation
- **Power BI**: DAX measures, data modeling, interactive visuals
- **Excel**: Source data exploration

