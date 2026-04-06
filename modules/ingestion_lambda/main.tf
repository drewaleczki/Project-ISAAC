# 1. Zip local Python files into an archive transparently
data "archive_file" "lambda_zip" {
  type = "zip"
  # O Terraform aponta direto pra pasta do repositório:
  source_file = "${path.root}/src/ingestion_lambda/lambda_function.py"
  output_path = "${path.root}/src/ingestion_lambda/lambda_function.zip"
}

# 2. IAM Role: Create a Role for the Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-ingestion-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 3. IAM Policy: Least Privilege (Only putObject in Bronze + CloudWatch Logs)
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project_name}-s3-writer-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::${var.bronze_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 4. AWS Lambda Execution block
resource "aws_lambda_function" "ingestion" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-crawler-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  # Tracks code changes so it redraws Lambda on Github if python code changes:
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime     = "python3.10"
  timeout     = 300 # 5 Minutos (Para garantir o download do e-commerce grande)
  memory_size = 512 # RAM segura pra carregar ZIP e Boto3 Client em paralalelo

  environment {
    variables = {
      KAGGLE_USERNAME    = var.kaggle_username
      KAGGLE_KEY         = var.kaggle_key
      BRONZE_BUCKET_NAME = var.bronze_bucket_name
    }
  }
}
