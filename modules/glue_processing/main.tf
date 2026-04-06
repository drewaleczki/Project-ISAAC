# 1. Metastore: Glue Data Catalog Databases
resource "aws_glue_catalog_database" "bronze" {
  name        = "isaac_bronze"
  description = "Database for raw CSV tables landed in Bronze tier."
}

resource "aws_glue_catalog_database" "silver" {
  name        = "isaac_silver"
  description = "Database for optimized Parquet tables ready for analytical queries and dbt consumption."
}

# 2. Dynamic S3 Infrastructure enabling Python Script deployment
resource "aws_s3_object" "job_script" {
  bucket = var.silver_bucket_name
  key    = "scripts/bronze_to_silver.py"
  source = "${path.root}/src/glue/bronze_to_silver.py"

  # Drives targeted infrastructure updates when detecting script source code local MD5 hash variances
  source_hash = filemd5("${path.root}/src/glue/bronze_to_silver.py")
}

# 3. IAM Role Strategy: Strict Least Privilege Execution
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_execution" {
  name               = "${var.project_name}-glue-pyspark-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

# Binds AWS managed policies enabling foundational background Glue cluster boot behavior
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Restricts operations securely spanning Bronze Bucket (Read) and Silver Bucket (Write) borders 
resource "aws_iam_role_policy" "s3_lake_access" {
  name = "${var.project_name}-s3-boundary"
  role = aws_iam_role.glue_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.bronze_bucket_name}",
          "arn:aws:s3:::${var.bronze_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${var.silver_bucket_name}",
          "arn:aws:s3:::${var.silver_bucket_name}/*"
        ]
      }
    ]
  })
}

# 4. Orchestrating the Core AWS Glue Data Catalog Job Blueprint
resource "aws_glue_job" "bronze_to_silver" {
  name         = "${var.project_name}-bronze-to-silver-${var.environment}"
  role_arn     = aws_iam_role.glue_execution.arn
  glue_version = "4.0" # Maps functionally to target Engine: Spark 3.3 alongside Python 3.10 natively

  # Strategic FinOps Policy: Clamping environment explicitly using minimal dual G.1X compute nodes bypassing massive default expenses 
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${var.silver_bucket_name}/${aws_s3_object.job_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--BRONZE_BUCKET"                    = var.bronze_bucket_name
    "--SILVER_BUCKET"                    = var.silver_bucket_name
    "--enable-job-insights"              = "true"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-glue-datacatalog"          = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }
}
