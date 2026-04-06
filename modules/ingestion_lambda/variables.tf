variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "bronze_bucket_name" {
  description = "Tells Lambda exactly where the Bronze bucket is located."
  type        = string
}

variable "kaggle_username" {
  description = "Kaggle API Username from GitHub Secrets"
  type        = string
  sensitive   = true
}

variable "kaggle_key" {
  description = "Kaggle API Key Token from GitHub Secrets"
  type        = string
  sensitive   = true
}
