# This file contains the configuration for Prometheus workspaces in AWS.

# AWS Configuration
aws_region = "eu-north-1"  # Change to your preferred region

# Workspace Configuration
workspace_name = "prometheus"
environment    = "production"  # Options: development, staging, production

# Logging Configuration
enable_logging      = true
log_retention_days  = 30  # 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653

# Monitoring Configuration
enable_alert_manager = true
enable_rule_groups   = true

# Alert Manager Configuration
webhook_url = ""  # Leave empty to use Lambda webhook, or provide custom webhook URL

# Notification Channels Configuration
notification_channels = {
  # Email notifications via SNS
  email = {
    enabled = true
    address = "ezebuikemichael@gmail.com"  # Replace with your email
  }
  
  # Slack notifications
  slack = {
    enabled     = true
    webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"  # Replace with your Slack webhook
    channel     = "#alerts"  # Slack channel name
    username    = "Prometheus Bot"
  }
  
  # Discord notifications
  discord = {
    enabled     = true
    webhook_url = "https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"  # Replace with Discord webhook
    username    = "Prometheus Bot"
  }
  
  # Microsoft Teams notifications
  teams = {
    enabled     = true
    webhook_url = "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK"  # Replace with Teams webhook
  }
  
  # PagerDuty integration
  pagerduty = {
    enabled         = true
    integration_key = "YOUR_PAGERDUTY_INTEGRATION_KEY"  # Replace with PagerDuty integration key
    severity_map = {
      critical = "critical"
      warning  = "warning"
      info     = "info"
    }
  }
}

# Legacy configuration (for backward compatibility)
# enable_sns_notifications = true
# notification_email      = "alerts@yourcompany.com"

# Lambda webhook function
create_lambda_webhook = true

# How to get webhook URLs:
# 
# Slack:
# 1. Go to https://api.slack.com/apps
# 2. Create new app or select existing
# 3. Go to "Incoming Webhooks" and activate
# 4. Add webhook to workspace and copy URL
#
# Discord:
# 1. Go to your Discord server settings
# 2. Select "Integrations" → "Webhooks"
# 3. Create webhook and copy URL
#
# Microsoft Teams:
# 1. Go to Teams channel
# 2. Click "..." → "Connectors"
# 3. Add "Incoming Webhook" and copy URL
#
# PagerDuty:
# 1. Go to PagerDuty dashboard
# 2. Services → Select service → Integrations
# 3. Add "Events API v2" integration
# 4. Copy Integration Key

common_tags = {
  Name        = local.owners
  Environment = var.environment
  Project     = var.project_name
  Business    = var.business_division
}