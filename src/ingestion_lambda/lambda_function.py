import os
import io
import json
import base64
import zipfile
import urllib.request
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Initializing Olist Dataset Ingestion Lambda (Kaggle)")
    
    # 1. Retrieve credentials and environment variables
    kaggle_user = os.environ.get('KAGGLE_USERNAME')
    kaggle_key = os.environ.get('KAGGLE_KEY')
    bucket_name = os.environ.get('BRONZE_BUCKET_NAME')
    
    if not all([kaggle_user, kaggle_key, bucket_name]):
        raise ValueError("Missing Required Environment Variables in Lambda.")
    
    # 2. Call the Root Authenticated API to download the ZIP payload
    url = "https://www.kaggle.com/api/v1/datasets/download/olistbr/brazilian-ecommerce"
    
    auth_str = f"{kaggle_user}:{kaggle_key}"
    auth_b64 = base64.b64encode(auth_str.encode('ascii')).decode('ascii')
    
    req = urllib.request.Request(url)
    req.add_header('Authorization', f'Basic {auth_b64}')
    
    logger.info("Executing Kaggle API Download (In-Memory Streaming)...")
    try:
        response = urllib.request.urlopen(req)
        zip_content = response.read()
    except Exception as e:
        logger.error(f"Download Error: {e}")
        raise e
        
    logger.info("Download completed. Extracting Zip buffer and uploading into AWS S3...")
    
    s3_client = boto3.client('s3')
    uploaded_counts = 0
    
    # 3. Read ZIP entirely in memory (avoids ephemeral disk IO bottlenecks)
    with zipfile.ZipFile(io.BytesIO(zip_content)) as z:
        for file_name in z.namelist():
            if file_name.endswith('.csv'):
                logger.info(f"Uploading file: {file_name}")
                file_data = z.read(file_name)
                
                # Ex: olist_customers_dataset.csv -> olist_customers_dataset/olist_customers_dataset.csv
                table_name = file_name.replace(".csv", "")
                s3_key = f"olist/{table_name}/{file_name}"
                
                s3_client.put_object(
                    Bucket=bucket_name,
                    Key=s3_key,
                    Body=file_data
                )
                uploaded_counts += 1
                
    logger.info(f"Ingestion successful! {uploaded_counts} files injected into S3 Bronze tier: s3://{bucket_name}/olist/")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Ingestion pipeline successfully executed!')
    }
