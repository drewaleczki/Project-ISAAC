output "datalake_bronze_bucket" {
  description = "The name of the Bronze layer bucket"
  value       = module.s3_datalake.bronze_bucket_id
}

output "datalake_silver_bucket" {
  description = "The name of the Silver layer bucket"
  value       = module.s3_datalake.silver_bucket_id
}

output "datalake_gold_bucket" {
  description = "The name of the Gold layer bucket"
  value       = module.s3_datalake.gold_bucket_id
}
