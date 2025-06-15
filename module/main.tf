# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Local values for notification channels with backward compatibility
locals {
  # Handle legacy variables
  email_enabled = var.enable_sns_notifications != null ? var.enable_sns_notifications : var.notification_channels.email.enabled
  email_address = var.notification_email != "" ? var.notification_email : var.notification_channels.email.address
  
  # Final notification channels configuration
  notification_channels = {
    email = {
      enabled = local.email_enabled
      address = local.email_address
    }
    slack     = var.notification_channels.slack
    discord   = var.notification_channels.discord
    teams     = var.notification_channels.teams
    pagerduty = var.notification_channels.pagerduty
  }
  
  # Check if any notification channel is enabled
  any_notifications_enabled = (
    local.notification_channels.email.enabled ||
    local.notification_channels.slack.enabled ||
    local.notification_channels.discord.enabled ||
    local.notification_channels.teams.enabled ||
    local.notification_channels.pagerduty.enabled
  )
}

# Amazon Managed Service for Prometheus Workspace
resource "aws_prometheus_workspace" "prometheus" {
  alias = var.workspace_name

  tags = {
    Name        = var.workspace_name
    Environment = var.environment
    ManagedBy   = "Pezebuike"
    CreatedBy   = data.aws_caller_identity.current.user_id
  }
}

# CloudWatch Log Group for Prometheus (optional)
resource "aws_cloudwatch_log_group" "prometheus_logs" {
  count             = var.enable_logging ? 1 : 0
  name              = "/aws/prometheus/${var.workspace_name}"
  retention_in_days = var.log_retention_days  

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-${var.workspace_name}-logs"
    }
  )
}