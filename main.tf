terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configuration for GitHub Actions / CI pipeline (S3 Backend)
  backend "s3" {
    bucket = "tf-state-project-isaac-andre"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Project ISAAC"
      Environment = "Development"
      ManagedBy   = "Terraform"
    }
  }
}

module "s3_datalake" {
  source = "./modules/s3_datalake"

  project_name = "project-isaac"
  environment  = "dev"
}

module "ingestion_lambda" {
  source = "./modules/ingestion_lambda"

  project_name = "project-isaac"
  environment  = "dev"

  # Module integration! The bucket provisioned above feeds the lambda below:
  bronze_bucket_name = module.s3_datalake.bronze_bucket_id

  kaggle_username = var.kaggle_username
  kaggle_key      = var.kaggle_key
}

module "glue_processing" {
  source = "./modules/glue_processing"

  project_name = "project-isaac"
  environment  = "dev"

  bronze_bucket_name = module.s3_datalake.bronze_bucket_id
  silver_bucket_name = module.s3_datalake.silver_bucket_id
}

module "orchestration" {
  source = "./modules/orchestration"

  project_name = "project-isaac"
  environment  = "dev"

  lambda_ingestion_arn = module.ingestion_lambda.lambda_arn
  glue_job_name        = module.glue_processing.glue_job_name
  gold_bucket_name     = module.s3_datalake.gold_bucket_id
  alert_email          = var.alert_email
}
