-- models/gold/gold_kpi_sales_monthly.sql

WITH orders AS (
    SELECT 
        order_id,
        order_purchase_timestamp,
        order_status
    FROM {{ source('isaac_silver', 'olist_orders_dataset') }}
    WHERE order_status = 'delivered'
),

payments AS (
    SELECT 
        order_id,
        SUM(payment_value) as total_revenue
    FROM {{ source('isaac_silver', 'olist_order_payments_dataset') }}
    GROUP BY order_id
),

items AS (
    SELECT 
        order_id,
        SUM(freight_value) as total_freight
    FROM {{ source('isaac_silver', 'olist_order_items_dataset') }}
    GROUP BY order_id
)

SELECT 
    -- Athena (Trino) uses natively substr out-of-the-box to effectively chunk ISO8601 strings into Months globally
    SUBSTR(CAST(o.order_purchase_timestamp AS VARCHAR), 1, 7) as sales_month,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(ROUND(SUM(p.total_revenue), 2), 0) as total_revenue,
    COALESCE(ROUND(SUM(i.total_freight), 2), 0) as total_freight,
    COALESCE(ROUND(SUM(p.total_revenue) / nullif(COUNT(DISTINCT o.order_id), 0), 2), 0) as average_ticket
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN items i ON o.order_id = i.order_id
GROUP BY 1
ORDER BY 1 DESC
