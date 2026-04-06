output "lambda_arn" {
  description = "ARN of the Bronze ingestion Lambda function."
  value       = aws_lambda_function.ingestion.arn
}
