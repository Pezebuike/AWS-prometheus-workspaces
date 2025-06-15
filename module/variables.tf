# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-north-1"
}

variable "workspace_name" {
  description = "Name for the Prometheus workspace"
  type        = string
  default     = "prometheus"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "enable_logging" {
  description = "Enable CloudWatch logging for the workspace"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_alert_manager" {
  description = "Enable Alert Manager for the workspace"
  type        = bool
  default     = true
}

variable "enable_rule_groups" {
  description = "Enable rule groups for the workspace"
  type        = bool
  default     = true
}

variable "webhook_url" {
  description = "Webhook URL for alert manager notifications"
  type        = string
  default     = ""
}

variable "sns_topic_name" {
  description = "Name for the SNS topic"
  type        = string
  default     = "prometheus-alerts"
}

variable "create_lambda_webhook" {
  description = "Create Lambda function to receive webhooks and forward to notification channels"
  type        = bool
  default     = true
}

# Notification Channels Configuration
variable "notification_channels" {
  description = "Configuration for different notification channels"
  type = object({
    email = optional(object({
      enabled = bool
      address = string
    }), { enabled = false, address = "" })

    slack = optional(object({
      enabled     = bool
      webhook_url = string
      channel     = string
      username    = string
    }), { enabled = false, webhook_url = "", channel = "#alerts", username = "Prometheus" })

    discord = optional(object({
      enabled     = bool
      webhook_url = string
      username    = string
    }), { enabled = false, webhook_url = "", username = "Prometheus" })

    teams = optional(object({
      enabled     = bool
      webhook_url = string
    }), { enabled = false, webhook_url = "" })

    pagerduty = optional(object({
      enabled         = bool
      integration_key = string
      severity_map = optional(map(string), {
        critical = "critical"
        warning  = "warning"
        info     = "info"
      })
    }), { enabled = false, integration_key = "", severity_map = {} })
  })

  default = {
    email = {
      enabled = true
      address = ""
    }
    slack = {
      enabled     = false
      webhook_url = ""
      channel     = "#alerts"
      username    = "Prometheus"
    }
    discord = {
      enabled     = false
      webhook_url = ""
      username    = "Prometheus"
    }
    teams = {
      enabled     = false
      webhook_url = ""
    }
    pagerduty = {
      enabled         = false
      integration_key = ""
      severity_map    = {}
    }
  }
}

# Legacy variables for backward compatibility (DEPRECATED)
# These will be removed in future versions
variable "enable_sns_notifications" {
  description = "Enable SNS notifications for alerts (DEPRECATED - use notification_channels.email.enabled)"
  type        = bool
  default     = null
}


variable "notification_email" {
  description = "Email address to receive alert notifications (leave empty to disable email notifications)"
  type        = string
  default     = ""

  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "notification_email must be a valid email address or empty string."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""

}

variable "business_division" {
  description = "Business Division name (e.g., dev, prod)"
  type        = string
  default     = ""
}