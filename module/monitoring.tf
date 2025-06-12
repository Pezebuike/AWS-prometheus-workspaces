# monitoring.tf

# Local values for webhook URL
locals {
  webhook_url = var.create_lambda_webhook && local.any_notifications_enabled ? aws_lambda_function_url.webhook_url[0].function_url : var.webhook_url
}

# Alert Manager Definition
resource "aws_prometheus_alert_manager_definition" "alert_manager" {
  count        = var.enable_alert_manager ? 1 : 0
  workspace_id = aws_prometheus_workspace.prometheus.id
  
  definition = base64encode(templatefile("${path.module}/alertmanager.yml", {
    webhook_url = local.webhook_url
  }))
}

# Rule Group Definition
resource "aws_prometheus_rule_group_namespace" "rules" {
  count        = var.enable_rule_groups ? 1 : 0
  name         = "prometheus-rules"
  workspace_id = aws_prometheus_workspace.prometheus.id
  
  data = base64encode(file("${path.module}/prometheus-rules.yml"))
}