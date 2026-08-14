USE cohort_retention_project;

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
rfm_base AS (
    SELECT 
        co.customer_unique_id,
        DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders), MAX(co.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT co.order_id) AS frequency,
        SUM(op.payment_value) AS monetary
    FROM customer_orders co
    JOIN order_payments op ON co.order_id = op.order_id
    GROUP BY co.customer_unique_id
)
SELECT * FROM rfm_base LIMIT 10;

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
rfm_base AS (
    SELECT 
        co.customer_unique_id,
        DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders), MAX(co.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT co.order_id) AS frequency,
        SUM(op.payment_value) AS monetary
    FROM customer_orders co
    JOIN order_payments op ON co.order_id = op.order_id
    GROUP BY co.customer_unique_id
),
rfm_scored AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
)
SELECT 
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE 
        WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Champions'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Loyal'
        WHEN r_score = 1 AND f_score >= 3 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
        WHEN r_score = 4 AND f_score = 4 THEN 'Lost'
        ELSE 'Needs Attention'
    END AS segment
FROM rfm_scored;


SELECT segment, COUNT(*) AS customer_count, ROUND(AVG(monetary), 2) AS avg_monetary, ROUND(AVG(frequency), 2) AS avg_frequency, ROUND(AVG(recency_days), 0) AS avg_recency_days
FROM (
    WITH customer_orders AS (
        SELECT 
            c.customer_unique_id,
            o.order_id,
            o.order_purchase_timestamp
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        WHERE o.order_status NOT IN ('canceled', 'unavailable')
    ),
    rfm_base AS (
        SELECT 
            co.customer_unique_id,
            DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders), MAX(co.order_purchase_timestamp)) AS recency_days,
            COUNT(DISTINCT co.order_id) AS frequency,
            SUM(op.payment_value) AS monetary
        FROM customer_orders co
        JOIN order_payments op ON co.order_id = op.order_id
        GROUP BY co.customer_unique_id
    ),
    rfm_scored AS (
        SELECT 
            customer_unique_id,
            recency_days,
            frequency,
            monetary,
            NTILE(4) OVER (ORDER BY recency_days ASC) AS r_score,
            NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
            NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
        FROM rfm_base
    )
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CASE 
            WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Champions'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Loyal'
            WHEN r_score = 1 AND f_score >= 3 THEN 'New Customers'
            WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
            WHEN r_score = 4 AND f_score = 4 THEN 'Lost'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
) AS rfm_final
GROUP BY segment
ORDER BY customer_count DESC;