output "bronze_bucket_id" {
  description = "The name of the Bronze bucket"
  value       = aws_s3_bucket.bronze.id
}

output "silver_bucket_id" {
  description = "The name of the Silver bucket"
  value       = aws_s3_bucket.silver.id
}

output "gold_bucket_id" {
  description = "The name of the Gold bucket"
  value       = aws_s3_bucket.gold.id
}
