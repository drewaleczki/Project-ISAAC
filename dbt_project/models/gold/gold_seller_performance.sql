-- models/gold/gold_seller_performance.sql

WITH sellers AS (
    SELECT 
        seller_id, 
        seller_city, 
        seller_state
    FROM {{ source('isaac_silver', 'olist_sellers_dataset') }}
),

items AS (
    SELECT 
        order_id, 
        seller_id, 
        price
    FROM {{ source('isaac_silver', 'olist_order_items_dataset') }}
),

reviews AS (
    SELECT 
        order_id, 
        review_score
    FROM {{ source('isaac_silver', 'olist_order_reviews_dataset') }}
)

SELECT
    s.seller_id,
    MAX(s.seller_state) as seller_state,
    COUNT(DISTINCT i.order_id) as total_orders_fulfilled,
    ROUND(SUM(i.price), 2) as total_revenue_generated,
    ROUND(AVG(CAST(r.review_score AS DOUBLE)), 2) as average_review_score
FROM sellers s
JOIN items i ON s.seller_id = i.seller_id
LEFT JOIN reviews r ON i.order_id = r.order_id
GROUP BY 1
ORDER BY total_revenue_generated DESC
