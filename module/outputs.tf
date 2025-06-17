output "prometheus_workspace_id" {
  description = "The Prometheus workspace ID"
  value       = aws_prometheus_workspace.prometheus.id
}

output "prometheus_workspace_arn" {
  description = "The Prometheus workspace ARN"
  value       = aws_prometheus_workspace.prometheus.arn
}

output "prometheus_endpoint" {
  description = "The Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.prometheus.prometheus_endpoint
}

output "remote_write_url" {
  description = "The remote write URL for the Prometheus workspace"
  value       = "${aws_prometheus_workspace.prometheus.prometheus_endpoint}api/v1/remote_write"
}

output "query_url" {
  description = "The query URL for the Prometheus workspace"
  value       = "${aws_prometheus_workspace.prometheus.prometheus_endpoint}api/v1/query"
}

output "workspace_status" {
  description = "The status of the Prometheus workspace"
  value       = aws_prometheus_workspace.prometheus.arn # or use .id or .workspace_id
}


output "workspace_region" {
  description = "The AWS region where the workspace is created"
  value       = var.aws_region
}

output "ec2_instance_profile_name" {
  description = "Instance profile name for EC2 instances to send metrics"
  value       = aws_iam_instance_profile.prometheus_ec2_profile.name
}

output "ec2_instance_profile_arn" {
  description = "Instance profile ARN for EC2 instances to send metrics"
  value       = aws_iam_instance_profile.prometheus_ec2_profile.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for Prometheus logs"
  value       = var.enable_logging ? aws_cloudwatch_log_group.prometheus_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for Prometheus logs"
  value       = var.enable_logging ? aws_cloudwatch_log_group.prometheus_logs[0].arn : null
}

# SNS Outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for Prometheus alerts"
  value       = local.notification_channels.email.enabled ? aws_sns_topic.prometheus_alerts[0].arn : null
}

output "sns_topic_name" {
  description = "SNS topic name for Prometheus alerts"
  value       = local.notification_channels.email.enabled ? aws_sns_topic.prometheus_alerts[0].name : null
}

output "notification_email" {
  description = "Email address configured for notifications"
  value       = local.notification_channels.email.address != "" ? local.notification_channels.email.address : null
}

# Notification Channels Summary
output "enabled_notification_channels" {
  description = "List of enabled notification channels"
  value = [
    for channel, config in local.notification_channels : channel
    if try(config.enabled, false)
  ]
}

output "notification_channels_config" {
  description = "Summary of notification channels configuration"
  value = {
    email     = local.notification_channels.email.enabled
    slack     = local.notification_channels.slack.enabled
    discord   = local.notification_channels.discord.enabled
    teams     = local.notification_channels.teams.enabled
    pagerduty = local.notification_channels.pagerduty.enabled
  }
  sensitive = false
}

# Lambda Outputs
output "lambda_webhook_function_name" {
  description = "Lambda function name for webhook processing"
  value       = var.create_lambda_webhook && local.any_notifications_enabled ? aws_lambda_function.webhook_to_notifications[0].function_name : null
}

output "lambda_webhook_function_arn" {
  description = "Lambda function ARN for webhook processing"
  value       = var.create_lambda_webhook && local.any_notifications_enabled ? aws_lambda_function.webhook_to_notifications[0].arn : null
}

output "lambda_webhook_url" {
  description = "Lambda function URL for webhook endpoint"
  value       = var.create_lambda_webhook && local.any_notifications_enabled ? aws_lambda_function_url.webhook_url[0].function_url : null
}

output "webhook_endpoint" {
  description = "Active webhook URL for Alert Manager"
  value       = local.webhook_url
}

# Slack Configuration (masked for security)
output "slack_configuration" {
  description = "Slack notification configuration summary"
  value = local.notification_channels.slack.enabled ? {
    enabled            = true
    channel            = local.notification_channels.slack.channel
    username           = local.notification_channels.slack.username
    webhook_configured = local.notification_channels.slack.webhook_url != ""
  } : { enabled = false }
  sensitive = false
}

# Discord Configuration (masked for security)
output "discord_configuration" {
  description = "Discord notification configuration summary"
  value = local.notification_channels.discord.enabled ? {
    enabled            = true
    username           = local.notification_channels.discord.username
    webhook_configured = local.notification_channels.discord.webhook_url != ""
  } : { enabled = false }
  sensitive = false
}

# Teams Configuration (masked for security)
output "teams_configuration" {
  description = "Microsoft Teams notification configuration summary"
  value = local.notification_channels.teams.enabled ? {
    enabled            = true
    webhook_configured = local.notification_channels.teams.webhook_url != ""
  } : { enabled = false }
  sensitive = false
}


# # Outputs
# output "github_actions_role_arn" {
#   description = "ARN of the GitHub Actions OIDC role"
#   value       = var.create_oidc_role ? aws_iam_role.github_actions[0].arn : null
# }

# output "oidc_provider_arn" {
#   description = "ARN of the GitHub OIDC identity provider"
#   value       = var.create_oidc_role ? aws_iam_openid_connect_provider.github_actions[0].arn : null
# }

# output "github_repository_config" {
#   description = "GitHub repository configuration for OIDC"
#   value = var.create_oidc_role ? {
#     username       = var.github_username
#     repository     = var.github_repository
#     oidc_condition = "repo:${var.github_username}/${var.github_repository}:*"
#   } : null
# }




# # PagerDuty Configuration (masked for security)
# output "pagerduty_configuration" {
#   description = "PagerDuty notification configuration summary"
#   value = local.notification_channels.pagerduty.enabled ? {
#     enabled = true
#     integration_key_configured = local.notification_channels.pagerduty.integration_key != ""
#     severity_mapping = local.notification_channels.pagerduty.severity_map
#   } : { enabled = false }
#   sensitive = false
# }