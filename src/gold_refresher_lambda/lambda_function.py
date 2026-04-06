import os
import time
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

athena = boto3.client('athena')

GOLD_BUCKET = os.environ['GOLD_BUCKET_NAME']
STAGING_DIR = f"s3://{GOLD_BUCKET}/athena_query_results/"
DATABASE = "isaac_gold"

# Analytical SQL models to refresh on every scheduled pipeline execution
GOLD_MODELS = {
    "gold_kpi_sales_monthly": """
        CREATE TABLE IF NOT EXISTS isaac_gold.gold_kpi_sales_monthly
        WITH (format='PARQUET', write_compression='SNAPPY',
              external_location='s3://{gold_bucket}/curated_models/gold_kpi_sales_monthly/')
        AS
        WITH orders AS (
            SELECT order_id, order_purchase_timestamp
            FROM isaac_silver.olist_orders_dataset
            WHERE order_status = 'delivered'
        ),
        payments AS (
            SELECT order_id, SUM(payment_value) AS total_revenue
            FROM isaac_silver.olist_order_payments_dataset GROUP BY order_id
        ),
        items AS (
            SELECT order_id, SUM(freight_value) AS total_freight
            FROM isaac_silver.olist_order_items_dataset GROUP BY order_id
        )
        SELECT
            SUBSTR(CAST(o.order_purchase_timestamp AS VARCHAR), 1, 7) AS sales_month,
            COUNT(DISTINCT o.order_id) AS total_orders,
            COALESCE(ROUND(SUM(p.total_revenue), 2), 0) AS total_revenue,
            COALESCE(ROUND(SUM(i.total_freight), 2), 0) AS total_freight,
            COALESCE(ROUND(SUM(p.total_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2), 0) AS average_ticket
        FROM orders o
        LEFT JOIN payments p ON o.order_id = p.order_id
        LEFT JOIN items i ON o.order_id = i.order_id
        GROUP BY 1 ORDER BY 1 DESC
    """,
    "gold_seller_performance": """
        CREATE TABLE IF NOT EXISTS isaac_gold.gold_seller_performance
        WITH (format='PARQUET', write_compression='SNAPPY',
              external_location='s3://{gold_bucket}/curated_models/gold_seller_performance/')
        AS
        WITH sellers AS (
            SELECT seller_id, seller_state FROM isaac_silver.olist_sellers_dataset
        ),
        items AS (
            SELECT order_id, seller_id, price FROM isaac_silver.olist_order_items_dataset
        ),
        reviews AS (
            SELECT order_id, review_score FROM isaac_silver.olist_order_reviews_dataset
        )
        SELECT
            s.seller_id,
            MAX(s.seller_state) AS seller_state,
            COUNT(DISTINCT i.order_id) AS total_orders_fulfilled,
            ROUND(SUM(i.price), 2) AS total_revenue_generated,
            ROUND(AVG(CAST(r.review_score AS DOUBLE)), 2) AS average_review_score
        FROM sellers s
        JOIN items i ON s.seller_id = i.seller_id
        LEFT JOIN reviews r ON i.order_id = r.order_id
        GROUP BY 1 ORDER BY total_revenue_generated DESC
    """
}


def _wait_for_query(execution_id, model_name):
    """Polls Athena until query completes or raises on failure."""
    while True:
        response = athena.get_query_execution(QueryExecutionId=execution_id)
        status = response['QueryExecution']['Status']['State']
        logger.info(f"[{model_name}] Status: {status}")

        if status == 'SUCCEEDED':
            return
        elif status in ('FAILED', 'CANCELLED'):
            reason = response['QueryExecution']['Status'].get('StateChangeReason', 'Unknown')
            raise RuntimeError(f"Athena query for {model_name} failed: {reason}")

        time.sleep(5)


def lambda_handler(event, context):
    logger.info("Gold Refresher Lambda started — refreshing analytical Gold Layer...")

    # Drop existing tables first to allow full overwrite on each pipeline run
    for model_name in GOLD_MODELS:
        drop_sql = f"DROP TABLE IF EXISTS {DATABASE}.{model_name}"
        logger.info(f"Dropping existing table: {model_name}")
        drop_response = athena.start_query_execution(
            QueryString=drop_sql,
            QueryExecutionContext={'Database': DATABASE, 'Catalog': 'AwsDataCatalog'},
            ResultConfiguration={'OutputLocation': STAGING_DIR}
        )
        _wait_for_query(drop_response['QueryExecutionId'], f"DROP {model_name}")

    # Recreate each model from fresh Silver data
    for model_name, sql_template in GOLD_MODELS.items():
        sql = sql_template.format(gold_bucket=GOLD_BUCKET)
        logger.info(f"Refreshing Gold model: {model_name}")
        response = athena.start_query_execution(
            QueryString=sql,
            QueryExecutionContext={'Database': DATABASE, 'Catalog': 'AwsDataCatalog'},
            ResultConfiguration={'OutputLocation': STAGING_DIR}
        )
        _wait_for_query(response['QueryExecutionId'], model_name)

    logger.info("Gold Layer refresh complete. All KPI models are up-to-date.")
    return {'statusCode': 200, 'body': 'Gold Layer refreshed successfully.'}
