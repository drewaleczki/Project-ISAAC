variable "aws_region" {
  description = "The primary AWS region where resources will be provisioned (e.g., us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "kaggle_username" {
  description = "Username for Kaggle API authentication"
  type        = string
  sensitive   = true
}

variable "kaggle_key" {
  description = "Key for Kaggle API authentication"
  type        = string
  sensitive   = true
}
