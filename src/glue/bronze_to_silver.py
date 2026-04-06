import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# 1. Retrieving Arguments passed via Terraform / AWS
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'BRONZE_BUCKET', 'SILVER_BUCKET'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 2. Native S3 Base Paths
bronze_path = f"s3://{args['BRONZE_BUCKET']}/olist/"
silver_path = f"s3://{args['SILVER_BUCKET']}/olist/"
silver_db = "isaac_silver"

# Dictionary of raw Kaggle dataset table names (CSV)
olist_tables = [
    "olist_customers_dataset",
    "olist_geolocation_dataset",
    "olist_order_items_dataset",
    "olist_order_payments_dataset",
    "olist_order_reviews_dataset",
    "olist_orders_dataset",
    "olist_products_dataset",
    "olist_sellers_dataset",
    "product_category_name_translation"
]

print(">>> Starting Olist Data Processing (Bronze to Silver) <<<")

# 3. Massive Iteration (PySpark applies high-performance DAG Execution)
for table_name in olist_tables:
    print(f"Reading and casting Bronze table: {table_name}")
    
    # Executes intelligent data type inference directly from raw CSVs
    df = spark.read.option("header", "true") \
                   .option("inferSchema", "true") \
                   .option("multiLine", "true") \
                   .option("escape", '"') \
                   .csv(f"{bronze_path}{table_name}/")
                   
    target_path = f"{silver_path}{table_name}/"
    
    print(f"Writing {table_name} in columnar format (PARQUET) to Silver tier...")
    
    # 4. Writes in highly compressed Parquet format and auto-registers to Glue Data Catalog (Metastore)
    df.write.mode("overwrite") \
            .format("parquet") \
            .option("path", target_path) \
            .saveAsTable(f"{silver_db}.{table_name}")

print(">>> Data Processing Finished Successfully <<<")
job.commit()
