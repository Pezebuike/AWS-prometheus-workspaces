
# AWS-prometheus-workspaces


Enterprise-ready Prometheus monitoring infrastructure using Amazon Managed Service for Prometheus (AMP) Features include automated workspace provisioning, multi-channel alert notifications (Email, Slack, Discord, Teams, PagerDuty), serverless webhook processing, comprehensive alerting rules, and secure IAM role management.

## Amazon Managed Service for Prometheus Terraform Configuration

This Terraform configuration sets up an Amazon Managed Service for Prometheus (AMP) workspace with comprehensive monitoring, alerting, and IAM configurations.

## File Structure

```

├── versions.tf                 # Terraform and provider version requirements
├── variables.tf                # Input variable definitions
├── main.tf                     # Core Prometheus workspace and CloudWatch resources
├── iam.tf                      # IAM roles, policies, and instance profiles
├── notifications.tf            # SNS, Lambda, and notification channel resources
├── monitoring.tf               # Alert Manager and Rule Groups configuration
├── outputs.tf                  # Output definitions
├── alertmanager.yml            # Alert Manager configuration template
├── prometheus-rules.yml        # Prometheus alerting and recording rules
├── lambda_webhook.py           # Lambda function code for webhook processing
├── terraform.tfvars.example    # Example variables file
└── README.md                   # This file
```

## Features

- **Prometheus Workspace**: Fully managed Prometheus workspace
- **IAM Integration**: Proper roles for workspace and EC2 instances
- **Alert Manager**: Configurable alerting with webhook support
- **Multi-Channel Notifications**: Email (SNS), Slack, Discord, Microsoft Teams, PagerDuty
- **Lambda Webhook**: Serverless webhook processor for alert forwarding
- **Rule Groups**: Pre-configured alerting and recording rules
- **CloudWatch Logging**: Optional logging integration
- **Modular Design**: Easy to customize and extend

## Quick Start

1. **Clone or download the configuration files**

2. **Copy the example variables file:**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your values:**

   ```hcl
   aws_region      = "us-west-2"
   workspace_name  = "my-prometheus"
   environment     = "production"
   
   # Configure notification channels
   notification_channels = {
     email = {
       enabled = true
       address = "alerts@yourcompany.com"
     }
     slack = {
       enabled     = true
       webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK"
       channel     = "#alerts"
       username    = "Prometheus Bot"
     }
   }
   ```

4. **Initialize and apply Terraform:**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration Options

### Required Variables

- `aws_region`: AWS region for resources
- `workspace_name`: Name for the Prometheus workspace

### Optional Variables

- `environment`: Environment tag (default: "development")
- `enable_logging`: Enable CloudWatch logging (default: true)
- `log_retention_days`: Log retention period (default: 14)
- `enable_alert_manager`: Enable Alert Manager (default: true)
- `enable_rule_groups`: Enable rule groups (default: true)
- `webhook_url`: Custom webhook URL (default: uses Lambda webhook)
- `notification_channels`: Configuration object for all notification channels
- `create_lambda_webhook`: Create Lambda webhook function (default: true)

### Multi-Channel Notifications

The configuration supports multiple notification channels that can be enabled simultaneously:

#### 📧 **Email Notifications (SNS)**

```hcl
notification_channels = {
  email = {
    enabled = true
    address = "alerts@yourcompany.com"
  }
}
```

- **Features**: Rich HTML emails, automatic confirmation, SNS topic management
- **Setup**: Just provide email address, confirmation email will be sent

#### 💬 **Slack Integration**

```hcl
notification_channels = {
  slack = {
    enabled     = true
    webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK"
    channel     = "#alerts"
    username    = "Prometheus Bot"
  }
}
```

- **Features**: Rich formatting, color-coded alerts, threading support
- **Setup**: Create incoming webhook in Slack app settings
- **Example**: ![Slack Alert Example with red color for critical alerts]

#### 🎮 **Discord Integration**

```hcl
notification_channels = {
  discord = {
    enabled     = true
    webhook_url = "https://discord.com/api/webhooks/YOUR/WEBHOOK"
    username    = "Prometheus Bot"
  }
}
```

- **Features**: Embedded messages, color coding, bot customization
- **Setup**: Server Settings → Integrations → Webhooks

#### 👔 **Microsoft Teams Integration**

```hcl
notification_channels = {
  teams = {
    enabled     = true
    webhook_url = "https://outlook.office.com/webhook/YOUR/WEBHOOK"
  }
}
```

- **Features**: Adaptive cards, threaded conversations, @mentions
- **Setup**: Teams channel → Connectors → Incoming Webhook

#### 📟 **PagerDuty Integration**

```hcl
notification_channels = {
  pagerduty = {
    enabled         = true
    integration_key = "YOUR_INTEGRATION_KEY"
    severity_map = {
      critical = "critical"
      warning  = "warning"
      info     = "info"
    }
  }
}
```

- **Features**: Incident management, escalation policies, auto-resolution
- **Setup**: Service → Integrations → Events API v2

### Notification Examples

#### Slack Alert

```
🚨 HighMemoryUsage
Status: FIRING | Severity: CRITICAL
Instance: web-server-1
Job: node-exporter
Summary: Memory usage above 80% for 5 minutes
```

#### Discord Embed

Rich embedded message with:

- 🚨 Red color for critical alerts
- ⚠️ Yellow for warnings  
- ✅ Green for resolved
- Structured fields with instance details

#### Teams Adaptive Card

Professional card format with:

- Alert summary and status
- Organized fact tables
- Action buttons (if configured)
- Timeline information

### Alert Manager Configuration

The Alert Manager is configured with three severity levels:

- **Critical**: Immediate attention required
- **Warning**: Should be addressed soon
- **Info**: Informational alerts

Customize the `alertmanager.yml` file for your specific notification requirements.

### Prometheus Rules

The configuration includes several rule groups:

- **instance-monitoring**: Basic infrastructure monitoring
- **application-monitoring**: Application performance monitoring
- **kubernetes-monitoring**: Kubernetes-specific alerts (if applicable)
- **recording-rules**: Pre-computed metrics for efficiency

## Outputs

After deployment, Terraform will output:

- Workspace ID and ARN
- Prometheus endpoints (query and remote write URLs)
- IAM role and instance profile information
- CloudWatch log group details
- Enabled notification channels summary
- Lambda webhook function details and URL
- Masked configuration summaries for each channel

## Security Considerations

- IAM roles follow the principle of least privilege
- Instance profiles are provided for EC2 integration
- CloudWatch logs are encrypted by default
- All resources are tagged for proper governance

## Setting Up Notification Channels

### 📧 Email (SNS) Setup

1. **No setup required** - just provide email address in configuration
2. **Confirm subscription** after deployment (check email for confirmation link)
3. **Test**: `aws sns publish --topic-arn <topic-arn> --message "Test"`

### 💬 Slack Setup

1. **Go to**: https://api.slack.com/apps
2. **Create app** or select existing app
3. **Enable Incoming Webhooks**: Features → Incoming Webhooks → On
4. **Add webhook**: Click "Add New Webhook to Workspace"
5. **Select channel** and authorize
6. **Copy webhook URL** and add to terraform.tfvars

### 🎮 Discord Setup

1. **Open Discord server** where you want notifications
2. **Server Settings** → Integrations → Webhooks
3. **Create Webhook**
4. **Configure**: Set name, avatar, channel
5. **Copy Webhook URL** and add to configuration

### 👔 Microsoft Teams Setup

1. **Open Teams channel** for notifications
2. **Click "..." menu** → Connectors
3. **Find "Incoming Webhook"** → Configure
4. **Provide name and upload image** (optional)
5. **Copy webhook URL** and add to configuration

### 📟 PagerDuty Setup

1. **Go to PagerDuty** → Services
2. **Select service** or create new one
3. **Integrations tab** → Add integration
4. **Choose "Events API v2"**
5. **Copy Integration Key** and add to configuration

## Notification Channel Examples

### EC2 Instance Integration

To send metrics from EC2 instances, attach the output instance profile:

```hcl
resource "aws_instance" "example" {
  # ... other configuration
  iam_instance_profile = module.prometheus.ec2_instance_profile_name
}
```

### Kubernetes Integration

For EKS clusters, use the workspace endpoints with appropriate service accounts and IRSA.

### Application Integration

Use the remote write URL output to configure your applications:

```
Remote Write URL: https://aps-workspaces.region.amazonaws.com/workspaces/ws-xxx/api/v1/remote_write
```

## Customization

### Adding Custom Rules

Edit `prometheus-rules.yml` to add your specific alerting rules:

```yaml
- alert: CustomAlert
  expr: your_metric > threshold
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Custom alert fired"
    description: "Your custom description"
```

### Modifying Alert Manager

Update `alertmanager.yml` to integrate with your notification systems:

- Slack webhooks
- PagerDuty integrations
- Email notifications
- Custom webhook endpoints

### Scaling Considerations

For high-volume environments, consider:

- Increasing log retention based on compliance requirements
- Implementing metric filtering to reduce costs
- Using recording rules for frequently queried metrics
- Setting up cross-region replication for disaster recovery

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your AWS credentials have sufficient permissions
2. **Resource Limits**: Check AWS service quotas for your region
3. **Webhook Failures**: Verify webhook URLs are accessible and properly formatted
4. **Email Not Received**: Check spam folder and confirm SNS subscription
5. **Lambda Errors**: Check CloudWatch logs for the webhook Lambda function
6. **Slack/Discord/Teams Not Working**: Verify webhook URLs are correct and channels exist
7. **PagerDuty Incidents Not Created**: Check integration key and service configuration

### Notification Channel Troubleshooting

#### 📧 **Email Issues**

```bash
# Check SNS subscription status
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)

# Test SNS publishing
aws sns publish --topic-arn $(terraform output -raw sns_topic_arn) --message "Test message"

# Confirm subscription
# Click the confirmation link in your email
```

#### 💬 **Slack Issues**

- **Webhook URL Invalid**: Ensure format is `https://hooks.slack.com/services/...`
- **Channel Not Found**: Verify channel exists and bot has access
- **App Permissions**: Check if app has permission to post to channel
- **Test**: Use curl to test webhook directly

#### 🎮 **Discord Issues**

- **Webhook Deleted**: Check if webhook still exists in Discord server
- **Channel Permissions**: Ensure webhook has permission to post
- **Rate Limiting**: Discord may rate limit frequent messages
- **Test**: Send test message via Discord webhook

#### 👔 **Teams Issues**

- **Connector Disabled**: Check if incoming webhook connector is still enabled
- **Tenant Restrictions**: Some organizations block external webhooks
- **Webhook Expired**: Teams webhooks may expire, recreate if needed

#### 📟 **PagerDuty Issues**

- **Integration Key Invalid**: Verify integration key is correct
- **Service Configuration**: Check if service accepts Events API v2
- **Deduplication**: Multiple alerts may be deduplicated by PagerDuty
- **Escalation Policy**: Ensure service has proper escalation configured

#### 🔍 **General Lambda Issues**

```bash
# Check Lambda function logs
aws logs tail /aws/lambda/$(terraform output -raw lambda_webhook_function_name) --follow

# Test Lambda function directly
aws lambda invoke --function-name $(terraform output -raw lambda_webhook_function_name) \
  --payload '{"body": "{\"alerts\": [{\"status\": \"firing\", \"labels\": {\"alertname\": \"TestAlert\", \"severity\": \"warning\"}}]}"}' \
  response.json

# Check enabled notification channels
terraform output enabled_notification_channels
```

### Useful Commands

```bash
# Check workspace status
aws amp describe-workspace --workspace-id $(terraform output -raw prometheus_workspace_id)

# Test remote write endpoint
curl -X POST $(terraform output -raw remote_write_url) \
  -H "Content-Type: application/x-protobuf" \
  -H "Content-Encoding: snappy"

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/prometheus"
```

### 📧 Email Notification

```
Subject: 🚨 Prometheus Alert: HighMemoryUsage (CRITICAL)

🚨 PROMETHEUS ALERT 🚨

Alert: HighMemoryUsage
Status: FIRING
Severity: CRITICAL
Instance: ip-10-0-1-100.ec2.internal
Job: node-exporter

Summary: High memory usage on ip-10-0-1-100.ec2.internal
Description: Memory usage is above 80% for more than 5 minutes.

Timeline:
Started: 2025-06-12 14:30:15 UTC
Ended: Ongoing
```

### 💬 Slack Notification

```
🚨 HighMemoryUsage
Status: FIRING | Severity: CRITICAL
Instance: ip-10-0-1-100.ec2.internal  
Job: node-exporter
Summary: Memory usage above 80% for 5 minutes

[Posted by Prometheus Bot in #alerts]
```

### 🎮 Discord Notification

Rich embed with:

- **Title**: 🚨 HighMemoryUsage
- **Color**: Red for critical
- **Fields**: Status, Severity, Instance
- **Footer**: Prometheus Alert Manager
- **Timestamp**: Current time

### 👔 Teams Notification

Adaptive card showing:

- **Header**: 🚨 Prometheus Alert
- **Title**: HighMemoryUsage - critical
- **Facts**: Status, Severity, Instance, Job
- **Theme**: Red color scheme

### 📟 PagerDuty Incident

- **Title**: HighMemoryUsage: Memory usage above 80%
- **Severity**: Critical (auto-mapped)
- **Source**: ip-10-0-1-100.ec2.internal
- **Component**: node-exporter
- **Auto-resolve**: When alert status becomes "resolved"

## Integration Examples

## Clean Up

To destroy all resources:

```bash
terraform destroy
```


## Contributing

Feel free to submit issues and enhancement requests or contribute improvements to this configuration.

## License

This configuration is provided for educational and reference purposes.
>>>>>>> 7ea4d49 (first commit)
