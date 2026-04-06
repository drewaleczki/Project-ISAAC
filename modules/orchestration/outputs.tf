output "state_machine_arn" {
  description = "ARN of the Step Functions State Machine orchestrating the full pipeline."
  value       = aws_sfn_state_machine.pipeline.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS Topic used for pipeline failure alerts."
  value       = aws_sns_topic.pipeline_alerts.arn
}
