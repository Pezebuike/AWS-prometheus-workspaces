# monitoring.tf

# Get current region
data "aws_region" "current" {}

# Local values for webhook URL
locals {
  webhook_url = var.create_lambda_webhook && local.any_notifications_enabled ? aws_lambda_function_url.webhook_url[0].function_url : var.webhook_url
}

# Email subscription to SNS topic for alert notifications
resource "aws_sns_topic_subscription" "email_notification" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.prometheus_alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_email

  # This will remain in "PendingConfirmation" state until user clicks confirmation link in email
}

# Optional: Output to remind user to check email
output "email_subscription_status" {
  value = var.notification_email != "" ? "Email subscription created for ${var.notification_email}. Check your email (including spam folder) for confirmation link." : "No email notifications configured"
}

# Alert Manager Definition using external template file
resource "aws_prometheus_alert_manager_definition" "alert_manager" {
  count        = var.enable_alert_manager ? 1 : 0
  workspace_id = aws_prometheus_workspace.prometheus.id

  definition = templatefile("${path.module}/alertmanager.yml", {
    sns_topic_arn = aws_sns_topic.prometheus_alerts[0].arn
    aws_region    = data.aws_region.current.name
  })
}




























































# resource "aws_prometheus_alert_manager_definition" "alert_manager" {
#   count        = var.enable_alert_manager ? 1 : 0
#   workspace_id = aws_prometheus_workspace.prometheus.id

#   definition = base64encode(templatefile("${path.module}/alertmanager.yml", {
#     sns_topic_arn = aws_sns_topic.prometheus_alerts[0].arn
#     aws_region    = data.aws_region.current.name
#   }))
# }

# Rule Group Definition using external rules file
resource "aws_prometheus_rule_group_namespace" "rules" {
  count        = var.enable_rule_groups ? 1 : 0
  name         = "prometheus-rules"
  workspace_id = aws_prometheus_workspace.prometheus.id

  data = file("${path.module}/prometheus-rules.yml")

  # data = base64encode(file("${path.module}/prometheus-rules.yml"))
}


# # Get current region
# data "aws_region" "current" {}

# # Local values for webhook URL
# locals {
#   webhook_url = var.create_lambda_webhook && local.any_notifications_enabled ? aws_lambda_function_url.webhook_url[0].function_url : var.webhook_url
# }

# # Email subscription to SNS topic for alert notifications
# resource "aws_sns_topic_subscription" "email_notification" {
#   count     = var.notification_email != "" ? 1 : 0
#   topic_arn = aws_sns_topic.prometheus_alerts[0].arn
#   protocol  = "email"
#   endpoint  = var.notification_email

#   # This will remain in "PendingConfirmation" state until user clicks confirmation link in email
# }

# # Optional: Output to remind user to check email
# output "email_subscription_status" {
#   value = var.notification_email != "" ? "Email subscription created for ${var.notification_email}. Check your email (including spam folder) for confirmation link." : "No email notifications configured"
# }

# # Alert Manager Definition using heredoc - NO base64encode
# resource "aws_prometheus_alert_manager_definition" "alert_manager" {
#   count        = var.enable_alert_manager ? 1 : 0
#   workspace_id = aws_prometheus_workspace.prometheus.id

#   definition = <<-EOT
# alertmanager_config: |
#   route:
#     receiver: 'default'
#   receivers:
#   - name: 'default'
#     sns_configs:
#     - topic_arn: '${aws_sns_topic.prometheus_alerts[0].arn}'
#       sigv4:
#         region: '${data.aws_region.current.name}'
# EOT
# }

# # Rule Group Definition with at least one rule
# resource "aws_prometheus_rule_group_namespace" "rules" {
#   count        = var.enable_rule_groups ? 1 : 0
#   name         = "prometheus-rules"
#   workspace_id = aws_prometheus_workspace.prometheus.id

#   data = <<-EOT
# groups:
# - name: basic-monitoring
#   rules:
#   - alert: InstanceDown
#     expr: up == 0
#     for: 5m
#     labels:
#       severity: critical
#     annotations:
#       summary: "Instance {{ $labels.instance }} down"
#       description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

#   - alert: HighCPUUsage
#     expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
#     for: 10m
#     labels:
#       severity: warning
#     annotations:
#       summary: "High CPU usage on {{ $labels.instance }}"
#       description: "CPU usage is above 80% for more than 10 minutes."

#   - alert: HighMemoryUsage
#     expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
#     for: 5m
#     labels:
#       severity: warning
#     annotations:
#       summary: "High memory usage on {{ $labels.instance }}"
#       description: "Memory usage is above 85%."
# EOT
# }