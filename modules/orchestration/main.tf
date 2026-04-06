# 1. SNS Topic: Pipeline failure alert channel
resource "aws_sns_topic" "pipeline_alerts" {
  name = "${var.project_name}-pipeline-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.pipeline_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 2. Gold Refresher Lambda: Re-materializes Gold Athena tables on each scheduled run
data "archive_file" "gold_refresher_zip" {
  type        = "zip"
  source_file = "${path.root}/src/gold_refresher_lambda/lambda_function.py"
  output_path = "${path.root}/src/gold_refresher_lambda/lambda_function.zip"
}

resource "aws_iam_role" "gold_refresher_role" {
  name = "${var.project_name}-gold-refresher-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "gold_refresher_policy" {
  name = "${var.project_name}-gold-refresher-policy"
  role = aws_iam_role.gold_refresher_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Athena: Execute and monitor queries targeting the Gold and Silver catalogs
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ]
        Resource = "*"
      },
      {
        # S3: Read Silver source data and write Gold output + staging results
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["arn:aws:s3:::*"]
      },
      {
        # Glue: Read Silver catalog metadata for Athena query resolution
        Effect   = "Allow"
        Action   = ["glue:GetTable", "glue:GetDatabase", "glue:GetPartitions"]
        Resource = "*"
      },
      {
        # CloudWatch: Enable Lambda execution logging
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "gold_refresher" {
  filename         = data.archive_file.gold_refresher_zip.output_path
  function_name    = "${var.project_name}-gold-refresher-${var.environment}"
  role             = aws_iam_role.gold_refresher_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.gold_refresher_zip.output_base64sha256
  runtime          = "python3.10"
  # Timeout accounts for two Athena CTAS queries completing sequentially
  timeout     = 300
  memory_size = 256

  environment {
    variables = {
      GOLD_BUCKET_NAME = var.gold_bucket_name
    }
  }
}

# 3. IAM Role for Step Functions: Orchestrates Lambda + Glue + SNS
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-sfn-orchestrator-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-sfn-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [var.lambda_ingestion_arn, aws_lambda_function.gold_refresher.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["glue:StartJobRun", "glue:GetJobRun", "glue:StopJobRun"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.pipeline_alerts.arn
      }
    ]
  })
}

# 4. Step Functions State Machine: The visual DAG of the full pipeline
resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-orchestrator-${var.environment}"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Project ISAAC — Automated End-to-End Data Pipeline (Bronze → Silver → Gold)"
    StartAt = "IngestBronze"
    States = {
      IngestBronze = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.lambda_ingestion_arn
          Payload      = {}
        }
        ResultPath = "$.ingestion_result"
        Next       = "ProcessSilver"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
          ResultPath  = "$.error"
        }]
      }

      ProcessSilver = {
        Type = "Task"
        # .sync native integration: Step Functions polls Glue automatically until job ends
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_name
        }
        ResultPath = "$.glue_result"
        Next       = "RefreshGold"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
          ResultPath  = "$.error"
        }]
      }

      RefreshGold = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.gold_refresher.arn
          Payload      = {}
        }
        ResultPath = "$.gold_result"
        Next       = "PipelineSucceeded"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
          ResultPath  = "$.error"
        }]
      }

      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn    = aws_sns_topic.pipeline_alerts.arn
          Subject     = "🚨 Project ISAAC — Pipeline Execution Failed"
          "Message.$" = "States.Format('Pipeline failed at step. Error details: {}', $.error)"
        }
        Next = "PipelineError"
      }

      PipelineSucceeded = {
        Type = "Succeed"
      }

      PipelineError = {
        Type  = "Fail"
        Error = "PipelineFailed"
        Cause = "One or more pipeline stages failed. Check CloudWatch logs for details."
      }
    }
  })
}

# 5. EventBridge Scheduler: Fires the pipeline daily at 06:00 UTC
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-eventbridge-scheduler-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${var.project_name}-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = aws_sfn_state_machine.pipeline.arn
    }]
  })
}

resource "aws_scheduler_schedule" "daily_pipeline" {
  name = "${var.project_name}-daily-pipeline-${var.environment}"

  flexible_time_window {
    mode = "OFF"
  }

  # Runs every day at 06:00 UTC (03:00 BRT)
  schedule_expression = "cron(0 6 * * ? *)"

  target {
    arn      = aws_sfn_state_machine.pipeline.arn
    role_arn = aws_iam_role.eventbridge_role.arn
    input    = jsonencode({ source = "EventBridge Scheduler — Daily Trigger" })
  }
}
