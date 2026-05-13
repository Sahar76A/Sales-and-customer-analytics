# Sales-and-customer-analytics
✅ Project Overview:

This project analyzes sales, customer, and product data to derive key business metrics and perform data quality checks.

✅ Files Provided:

Ashkan Moradi - Python Version.ipynb – Python notebook
Ashkan Moradi - SQL Version.sql – SQL script with all queries
README.md – This document

✅ How to Run:

Load the CSV files into your Python environment (or SQL environment) as tables (orders, order_items, products).
Use your database’s import tool or COPY/LOAD DATA command (in case of using in a SQL environment)
Run the script.
Review results for each section.

✅ Assumptions:

Each order_id in orders is unique.
Each order can contain multiple items in order_items.
Product details in the products table (like 'Category' and 'unit_cost') are correct.
the 'total_amount' in orders equals the sum of (quantity * unit_price) from order_items for that order.
All monetary values are stored in the same currency (No need for converting)
Dates are stored in YYYY-MM-DD format.
No taxes are considered unless included in unit_price or total_amount.

✅ Outputs Summary:

Sales Metrics Total revenue, total cost, and gross margin percentage by product category.
Customer Metrics
Top 2 customers by spending and average order value per customer.
Data Quality Checks
Identify missing references, data type mismatch, or missing values (Null) and duplicate values.
Frequently Purchased Product Pairs.
Top 3 combinations of products are often bought together in the same order.

✅ Data Quality Handling Approach:

Missing Foreign Keys: Enforce referential integrity constraints.
Mismatched Totals: Recalculate from order_items before loading to production.
Missing Values: Flag and filter out invalid records during preprocessing.
Duplicate Rows: check based on unique keys (order_id, product_id).
