# SNS Topic for Email Notifications
resource "aws_sns_topic" "prometheus_alerts" {
  count = local.notification_channels.email.enabled ? 1 : 0
  name  = "${var.workspace_name}-${var.sns_topic_name}"

  tags = {
    Name        = "${var.workspace_name}-${var.sns_topic_name}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "prometheus_alerts_policy" {
  count = local.notification_channels.email.enabled ? 1 : 0
  arn   = aws_sns_topic.prometheus_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.prometheus_alerts[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# # SNS Email Subscription
# resource "aws_sns_topic_subscription" "email_notification" {
#   count     = local.notification_channels.email.enabled && local.notification_channels.email.address != "" ? 1 : 0
#   topic_arn = aws_sns_topic.prometheus_alerts[0].arn
#   protocol  = "email"
#   endpoint  = local.notification_channels.email.address
# }

# Lambda function to receive webhooks and forward to notification channels
resource "aws_lambda_function" "webhook_to_notifications" {
  count         = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  filename      = "webhook_lambda.zip"
  function_name = "${var.workspace_name}-webhook-to-notifications"
  role          = aws_iam_role.lambda_webhook_role[0].arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 256

  source_code_hash = data.archive_file.lambda_webhook_zip[0].output_base64sha256

  environment {
    variables = {
      # Email/SNS configuration
      SNS_TOPIC_ARN = local.notification_channels.email.enabled ? aws_sns_topic.prometheus_alerts[0].arn : ""
      EMAIL_ENABLED = tostring(local.notification_channels.email.enabled)

      # Slack configuration
      SLACK_ENABLED     = tostring(local.notification_channels.slack.enabled)
      SLACK_WEBHOOK_URL = local.notification_channels.slack.webhook_url
      SLACK_CHANNEL     = local.notification_channels.slack.channel
      SLACK_USERNAME    = local.notification_channels.slack.username

      # Discord configuration
      DISCORD_ENABLED     = tostring(local.notification_channels.discord.enabled)
      DISCORD_WEBHOOK_URL = local.notification_channels.discord.webhook_url
      DISCORD_USERNAME    = local.notification_channels.discord.username

      # Microsoft Teams configuration
      TEAMS_ENABLED     = tostring(local.notification_channels.teams.enabled)
      TEAMS_WEBHOOK_URL = local.notification_channels.teams.webhook_url

      # PagerDuty configuration
      PAGERDUTY_ENABLED         = tostring(local.notification_channels.pagerduty.enabled)
      PAGERDUTY_INTEGRATION_KEY = local.notification_channels.pagerduty.integration_key
      PAGERDUTY_SEVERITY_MAP    = jsonencode(local.notification_channels.pagerduty.severity_map)
    }
  }

  tags = {
    Name        = "${var.workspace_name}-webhook-to-notifications"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_webhook_policy,
    aws_cloudwatch_log_group.lambda_webhook_logs,
  ]
}

# Lambda function code
data "archive_file" "lambda_webhook_zip" {
  count       = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  type        = "zip"
  output_path = "webhook_lambda.zip"

  source {
    content  = file("${path.module}/lambda_webhook.py")
    filename = "index.py"
  }
}

# Lambda Function URL for webhook endpoint
resource "aws_lambda_function_url" "webhook_url" {
  count              = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  function_name      = aws_lambda_function.webhook_to_notifications[0].function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST", "GET"]
    allow_headers     = ["date", "keep-alive", "content-type"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_webhook_logs" {
  count             = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  name              = "/aws/lambda/${var.workspace_name}-webhook-to-notifications"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.workspace_name}-webhook-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "lambda_webhook" {
  count     = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  topic_arn = aws_sns_topic.prometheus_alerts[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.webhook_to_notifications[0].arn
}

resource "aws_lambda_permission" "allow_sns" {
  count         = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_to_notifications[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.prometheus_alerts[0].arn
}