USE cohort_retention_project;

-- Check table structures
DESCRIBE orders;
DESCRIBE customers;
DESCRIBE order_payments;
DESCRIBE order_items;

-- Check date range of the dataset
SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) FROM orders;

-- Check for nulls in key columns
SELECT COUNT(*) AS total_orders,
       SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_dates,
       SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids
FROM orders;

-- Check order_status values (to understand what counts as a "real" order)
SELECT order_status, COUNT(*) 
FROM orders 
GROUP BY order_status 
ORDER BY COUNT(*) DESC;

-- Confirm customer_id is the right join key (check for duplicates)
SELECT customer_id, COUNT(*) 
FROM customers 
GROUP BY customer_id 
HAVING COUNT(*) > 1;