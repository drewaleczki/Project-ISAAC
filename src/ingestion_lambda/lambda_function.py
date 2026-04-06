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
    logger.info("Iniciando Lambda de Ingestão do Dataset Olist (Kaggle)")
    
    # 1. Recupera as credenciais e ambiente
    kaggle_user = os.environ.get('KAGGLE_USERNAME')
    kaggle_key = os.environ.get('KAGGLE_KEY')
    bucket_name = os.environ.get('BRONZE_BUCKET_NAME')
    
    if not all([kaggle_user, kaggle_key, bucket_name]):
        raise ValueError("Estão faltando Variáveis de Ambiente na Lambda.")
    
    # 2. Chama a API raiz autênticada para baixar o ZIP
    url = "https://www.kaggle.com/api/v1/datasets/download/olistbr/brazilian-ecommerce"
    
    auth_str = f"{kaggle_user}:{kaggle_key}"
    auth_b64 = base64.b64encode(auth_str.encode('ascii')).decode('ascii')
    
    req = urllib.request.Request(url)
    req.add_header('Authorization', f'Basic {auth_b64}')
    
    logger.info("Realizando Download pela API do Kaggle (Em memória)...")
    try:
        response = urllib.request.urlopen(req)
        zip_content = response.read()
    except Exception as e:
        logger.error(f"Erro no download: {e}")
        raise e
        
    logger.info("Download concluído. Extraindo arquivos (Zip) do Buffer e subindo para AWS S3...")
    
    s3_client = boto3.client('s3')
    uploaded_counts = 0
    
    # 3. Lê o ZIP em memória (evita salvar no disco efêmero e ser pesado)
    with zipfile.ZipFile(io.BytesIO(zip_content)) as z:
        for file_name in z.namelist():
            if file_name.endswith('.csv'):
                logger.info(f"Fazendo upload de: {file_name}")
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
                
    logger.info(f"Ingestão completa! {uploaded_counts} arquivos injetados na S3 Bronze: s3://{bucket_name}/olist/")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Sucesso na pipeline de ingestão!')
    }
