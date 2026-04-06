output "glue_job_name" {
  description = "Name of the Bronze-to-Silver Glue Job for Step Functions orchestration."
  value       = aws_glue_job.bronze_to_silver.name
}
