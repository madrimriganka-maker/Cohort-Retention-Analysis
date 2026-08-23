USE cohort_retention_project;
#revenue and order trends
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(op.payment_value) AS total_revenue,
    ROUND(SUM(op.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

#geographic performance
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(op.payment_value) AS total_revenue,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

#delivery performance
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS order_count,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;