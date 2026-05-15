# E-commerce Sales Funnel & Marketing Performance Analysis (SQL) 🛒

## 📌 Business Context
Understanding the customer journey from the first click to the final purchase is vital for any e-commerce business. This project builds an analytical framework to evaluate user conversion paths and marketing ROI, transforming raw event logs into actionable business intelligence.

## 🎯 Project Objectives
- **Funnel Analysis:** Build a 5-stage sales funnel (Page View -> View Product -> Add to Cart -> Start Checkout -> Purchase).
- **Conversion Optimization:** Identify critical bottlenecks where users drop off.
- **Traffic Attribution:** Measure the effectiveness of different marketing channels (Organic, Paid, Social).

## 🛠 Tech Stack & SQL Techniques
- **Advanced SQL:** Utilizing **CTEs (Common Table Expressions)** for modular and readable code.
- **Conditional Aggregation:** Using `CASE WHEN` and `MAX()` to flag user progression across millions of rows.
- **Data Integrity:** Implementing `NULLIF` to handle division-by-zero during conversion rate calculations.
- **Window Functions:** Analyzing sequence of events per user session.

## 📈 Analytical Framework
1. **Event Marking:** Standardizing messy event logs into a structured user-stage table.
2. **Dual-Layer Conversion Rates:**
   - **Step-by-Step Conversion:** Rate between two consecutive steps (e.g., Cart to Checkout).
   - **Overall Conversion:** Rate from the very first step to the final purchase.
3. **Marketing Efficiency:** Calculating **Revenue per User** and **AOV (Average Order Value)** segmented by traffic source.

## 💡 Key Strategic Insights
- **The "Cart-to-Checkout" Gap:** Identified a 40% drop-off at the checkout stage, suggesting potential issues with payment gateway trust or shipping costs.
- **Channel Performance:** Paid Social has the highest "Add to Cart" rate, but Organic Search yields the highest AOV, suggesting a more loyal customer base from search intent.

## 🚀 Technical Snippet Preview
```sql
-- Example of calculating overall conversion rate using CTEs
WITH funnel_stages AS (
    SELECT 
        user_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS saw_page,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS bought
    FROM raw_events
    GROUP BY user_id
)
SELECT 
    SUM(bought) * 100.0 / NULLIF(SUM(saw_page), 0) AS overall_conversion_rate
FROM funnel_stages;
