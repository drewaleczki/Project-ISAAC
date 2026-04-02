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
