variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_ingestion_arn" {
  description = "ARN of the existing Bronze ingestion Lambda function."
  type        = string
}

variable "glue_job_name" {
  description = "Name of the existing Bronze-to-Silver Glue Job."
  type        = string
}

variable "gold_bucket_name" {
  description = "S3 Gold Bucket name for Gold Refresher Lambda and Athena staging."
  type        = string
}

variable "alert_email" {
  description = "Email address that will receive SNS failure alerts from the pipeline."
  type        = string
}
