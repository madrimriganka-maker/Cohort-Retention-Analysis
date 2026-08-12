USE cohort_retention_project;

-- Part 1: First order month per customer (defines their cohort)
WITH first_orders AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') AS cohort_month
    FROM orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY customer_id
)
SELECT * FROM first_orders LIMIT 10;

-- Part 2: Month number since first order, for every order
WITH first_orders AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') AS cohort_month
    FROM orders
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY customer_id
),
order_activity AS (
    SELECT 
        o.customer_id,
        f.cohort_month,
        TIMESTAMPDIFF(MONTH, f.cohort_month, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS month_number
    FROM orders o
    JOIN first_orders f ON o.customer_id = f.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
)
SELECT * FROM order_activity LIMIT 10;

USE cohort_retention_project;

-- Part 3 (revised): Final cohort retention table using customer_unique_id
WITH first_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m-01') AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
order_activity AS (
    SELECT 
        c.customer_unique_id,
        f.cohort_month,
        TIMESTAMPDIFF(MONTH, f.cohort_month, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')) AS month_number
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN first_orders f ON c.customer_unique_id = f.customer_unique_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
)
SELECT 
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_unique_id) AS active_customers
FROM order_activity
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;