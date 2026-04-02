resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  bucket_prefix = "${var.project_name}-${var.environment}"
}

# Raw / Bronze Layer
resource "aws_s3_bucket" "bronze" {
  bucket        = "${local.bucket_prefix}-bronze-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(var.tags, {
    Layer = "Bronze"
    Zone  = "Raw"
  })
}

resource "aws_s3_bucket_public_access_block" "bronze_pab" {
  bucket                  = aws_s3_bucket.bronze.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Trusted / Silver Layer
resource "aws_s3_bucket" "silver" {
  bucket        = "${local.bucket_prefix}-silver-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(var.tags, {
    Layer = "Silver"
    Zone  = "Trusted"
  })
}

resource "aws_s3_bucket_public_access_block" "silver_pab" {
  bucket                  = aws_s3_bucket.silver.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Refined / Gold Layer
resource "aws_s3_bucket" "gold" {
  bucket        = "${local.bucket_prefix}-gold-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(var.tags, {
    Layer = "Gold"
    Zone  = "Refined"
  })
}

resource "aws_s3_bucket_public_access_block" "gold_pab" {
  bucket                  = aws_s3_bucket.gold.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
