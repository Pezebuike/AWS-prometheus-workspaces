import json
import boto3
import os
import urllib3
from datetime import datetime

# Initialize clients
sns = boto3.client('sns')
http = urllib3.PoolManager()

# Environment variables
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
EMAIL_ENABLED = os.environ.get('EMAIL_ENABLED', 'false').lower() == 'true'

SLACK_ENABLED = os.environ.get('SLACK_ENABLED', 'false').lower() == 'true'
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')
SLACK_CHANNEL = os.environ.get('SLACK_CHANNEL', '#alerts')
SLACK_USERNAME = os.environ.get('SLACK_USERNAME', 'Prometheus')

DISCORD_ENABLED = os.environ.get('DISCORD_ENABLED', 'false').lower() == 'true'
DISCORD_WEBHOOK_URL = os.environ.get('DISCORD_WEBHOOK_URL', '')
DISCORD_USERNAME = os.environ.get('DISCORD_USERNAME', 'Prometheus')

TEAMS_ENABLED = os.environ.get('TEAMS_ENABLED', 'false').lower() == 'true'
TEAMS_WEBHOOK_URL = os.environ.get('TEAMS_WEBHOOK_URL', '')

PAGERDUTY_ENABLED = os.environ.get('PAGERDUTY_ENABLED', 'false').lower() == 'true'
PAGERDUTY_INTEGRATION_KEY = os.environ.get('PAGERDUTY_INTEGRATION_KEY', '')
PAGERDUTY_SEVERITY_MAP = json.loads(os.environ.get('PAGERDUTY_SEVERITY_MAP', '{}'))

def handler(event, context):
    """
    Lambda function to receive Prometheus Alert Manager webhooks
    and forward them to configured notification channels
    """
    
    try:
        # Parse the incoming webhook payload
        if 'body' in event:
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        else:
            body = event
        
        # Extract alert information
        alerts = body.get('alerts', [])
        group_labels = body.get('groupLabels', {})
        common_labels = body.get('commonLabels', {})
        common_annotations = body.get('commonAnnotations', {})
        external_url = body.get('externalURL', '')
        
        print(f"Processing {len(alerts)} alerts across enabled channels")
        
        # Send notifications to enabled channels
        notifications_sent = []
        
        # Email notifications via SNS
        if EMAIL_ENABLED and SNS_TOPIC_ARN:
            try:
                send_email_notifications(alerts, external_url)
                notifications_sent.append('email')
            except Exception as e:
                print(f"Error sending email notification: {str(e)}")
        
        # Slack notifications
        if SLACK_ENABLED and SLACK_WEBHOOK_URL:
            try:
                send_slack_notifications(alerts, external_url)
                notifications_sent.append('slack')
            except Exception as e:
                print(f"Error sending Slack notification: {str(e)}")
        
        # Discord notifications
        if DISCORD_ENABLED and DISCORD_WEBHOOK_URL:
            try:
                send_discord_notifications(alerts, external_url)
                notifications_sent.append('discord')
            except Exception as e:
                print(f"Error sending Discord notification: {str(e)}")
        
        # Microsoft Teams notifications
        if TEAMS_ENABLED and TEAMS_WEBHOOK_URL:
            try:
                send_teams_notifications(alerts, external_url)
                notifications_sent.append('teams')
            except Exception as e:
                print(f"Error sending Teams notification: {str(e)}")
        
        # PagerDuty notifications
        if PAGERDUTY_ENABLED and PAGERDUTY_INTEGRATION_KEY:
            try:
                send_pagerduty_notifications(alerts, external_url)
                notifications_sent.append('pagerduty')
            except Exception as e:
                print(f"Error sending PagerDuty notification: {str(e)}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': f'Successfully processed {len(alerts)} alerts',
                'processed_alerts': len(alerts),
                'notifications_sent': notifications_sent
            })
        }
        
    except Exception as e:
        print(f"Error processing webhook: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to process webhook'
            })
        }

def send_email_notifications(alerts, external_url):
    """Send email notifications via SNS"""
    if len(alerts) > 1:
        send_email_summary(alerts, external_url)
    elif len(alerts) == 1:
        send_individual_email(alerts[0], external_url)

def send_individual_email(alert, external_url):
    """Send notification for a single alert via email"""
    alert_name = alert.get('labels', {}).get('alertname', 'Unknown Alert')
    severity = alert.get('labels', {}).get('severity', 'unknown')
    status = alert.get('status', 'unknown')
    
    emoji = get_alert_emoji(severity, status)
    subject = f"{emoji} Prometheus Alert: {alert_name} ({severity.upper()})"
    
    message_body = format_email_alert(alert, external_url)
    send_sns_message(subject, message_body)

def send_email_summary(alerts, external_url):
    """Send summary notification for multiple alerts via email"""
    total_alerts = len(alerts)
    critical_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'critical'])
    warning_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'warning'])
    
    subject = f"🚨 Prometheus Alert Summary: {total_alerts} alerts ({critical_count} critical, {warning_count} warning)"
    message_body = format_email_summary(alerts, external_url)
    send_sns_message(subject, message_body)

def send_slack_notifications(alerts, external_url):
    """Send notifications to Slack"""
    if len(alerts) > 1:
        send_slack_summary(alerts, external_url)
    else:
        send_slack_individual(alerts[0], external_url)

def send_slack_individual(alert, external_url):
    """Send individual alert to Slack"""
    alert_name = alert.get('labels', {}).get('alertname', 'Unknown Alert')
    severity = alert.get('labels', {}).get('severity', 'unknown')
    status = alert.get('status', 'unknown')
    instance = alert.get('labels', {}).get('instance', 'unknown')
    summary = alert.get('annotations', {}).get('summary', 'No summary available')
    
    color = get_slack_color(severity, status)
    emoji = get_alert_emoji(severity, status)
    
    payload = {
        "channel": SLACK_CHANNEL,
        "username": SLACK_USERNAME,
        "icon_emoji": ":warning:",
        "attachments": [
            {
                "color": color,
                "title": f"{emoji} {alert_name}",
                "text": summary,
                "fields": [
                    {"title": "Status", "value": status.upper(), "short": True},
                    {"title": "Severity", "value": severity.upper(), "short": True},
                    {"title": "Instance", "value": instance, "short": True},
                    {"title": "Job", "value": alert.get('labels', {}).get('job', 'unknown'), "short": True}
                ],
                "footer": "Prometheus Alert Manager",
                "ts": int(datetime.now().timestamp())
            }
        ]
    }
    
    send_http_request(SLACK_WEBHOOK_URL, payload)

def send_slack_summary(alerts, external_url):
    """Send alert summary to Slack"""
    total_alerts = len(alerts)
    critical_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'critical'])
    warning_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'warning'])
    firing_count = len([a for a in alerts if a.get('status') == 'firing'])
    
    color = "danger" if critical_count > 0 else "warning"
    
    alert_list = []
    for alert in alerts[:5]:  # Show first 5 alerts
        alert_name = alert.get('labels', {}).get('alertname', 'Unknown')
        severity = alert.get('labels', {}).get('severity', 'unknown')
        status = alert.get('status', 'unknown')
        emoji = get_alert_emoji(severity, status)
        alert_list.append(f"{emoji} {alert_name} ({severity})")
    
    if len(alerts) > 5:
        alert_list.append(f"... and {len(alerts) - 5} more alerts")
    
    payload = {
        "channel": SLACK_CHANNEL,
        "username": SLACK_USERNAME,
        "icon_emoji": ":rotating_light:",
        "attachments": [
            {
                "color": color,
                "title": f"🚨 Prometheus Alert Summary",
                "text": f"*{total_alerts} alerts* ({critical_count} critical, {warning_count} warning, {firing_count} firing)",
                "fields": [
                    {
                        "title": "Active Alerts",
                        "value": "\n".join(alert_list),
                        "short": False
                    }
                ],
                "footer": "Prometheus Alert Manager",
                "ts": int(datetime.now().timestamp())
            }
        ]
    }
    
    send_http_request(SLACK_WEBHOOK_URL, payload)

def send_discord_notifications(alerts, external_url):
    """Send notifications to Discord"""
    if len(alerts) > 1:
        send_discord_summary(alerts, external_url)
    else:
        send_discord_individual(alerts[0], external_url)

def send_discord_individual(alert, external_url):
    """Send individual alert to Discord"""
    alert_name = alert.get('labels', {}).get('alertname', 'Unknown Alert')
    severity = alert.get('labels', {}).get('severity', 'unknown')
    status = alert.get('status', 'unknown')
    summary = alert.get('annotations', {}).get('summary', 'No summary available')
    
    color = get_discord_color(severity, status)
    emoji = get_alert_emoji(severity, status)
    
    payload = {
        "username": DISCORD_USERNAME,
        "embeds": [
            {
                "title": f"{emoji} {alert_name}",
                "description": summary,
                "color": color,
                "fields": [
                    {"name": "Status", "value": status.upper(), "inline": True},
                    {"name": "Severity", "value": severity.upper(), "inline": True},
                    {"name": "Instance", "value": alert.get('labels', {}).get('instance', 'unknown'), "inline": True}
                ],
                "footer": {"text": "Prometheus Alert Manager"},
                "timestamp": datetime.now().isoformat()
            }
        ]
    }
    
    send_http_request(DISCORD_WEBHOOK_URL, payload)

def send_discord_summary(alerts, external_url):
    """Send alert summary to Discord"""
    total_alerts = len(alerts)
    critical_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'critical'])
    warning_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'warning'])
    
    color = get_discord_color('critical' if critical_count > 0 else 'warning', 'firing')
    
    description = f"**{total_alerts} alerts active**\n"
    description += f"🚨 {critical_count} critical\n"
    description += f"⚠️ {warning_count} warning\n\n"
    
    for i, alert in enumerate(alerts[:5]):
        alert_name = alert.get('labels', {}).get('alertname', 'Unknown')
        severity = alert.get('labels', {}).get('severity', 'unknown')
        emoji = get_alert_emoji(severity, alert.get('status', 'firing'))
        description += f"{emoji} {alert_name} ({severity})\n"
    
    if len(alerts) > 5:
        description += f"... and {len(alerts) - 5} more alerts"
    
    payload = {
        "username": DISCORD_USERNAME,
        "embeds": [
            {
                "title": "🚨 Prometheus Alert Summary",
                "description": description,
                "color": color,
                "footer": {"text": "Prometheus Alert Manager"},
                "timestamp": datetime.now().isoformat()
            }
        ]
    }
    
    send_http_request(DISCORD_WEBHOOK_URL, payload)

def send_teams_notifications(alerts, external_url):
    """Send notifications to Microsoft Teams"""
    if len(alerts) > 1:
        send_teams_summary(alerts, external_url)
    else:
        send_teams_individual(alerts[0], external_url)

def send_teams_individual(alert, external_url):
    """Send individual alert to Microsoft Teams"""
    alert_name = alert.get('labels', {}).get('alertname', 'Unknown Alert')
    severity = alert.get('labels', {}).get('severity', 'unknown')
    status = alert.get('status', 'unknown')
    summary = alert.get('annotations', {}).get('summary', 'No summary available')
    
    theme_color = get_teams_color(severity, status)
    emoji = get_alert_emoji(severity, status)
    
    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": theme_color,
        "title": f"{emoji} Prometheus Alert",
        "summary": f"{alert_name} - {severity}",
        "sections": [
            {
                "activityTitle": alert_name,
                "activitySubtitle": summary,
                "facts": [
                    {"name": "Status", "value": status.upper()},
                    {"name": "Severity", "value": severity.upper()},
                    {"name": "Instance", "value": alert.get('labels', {}).get('instance', 'unknown')},
                    {"name": "Job", "value": alert.get('labels', {}).get('job', 'unknown')}
                ]
            }
        ]
    }
    
    send_http_request(TEAMS_WEBHOOK_URL, payload)

def send_teams_summary(alerts, external_url):
    """Send alert summary to Microsoft Teams"""
    total_alerts = len(alerts)
    critical_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'critical'])
    warning_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'warning'])
    
    theme_color = get_teams_color('critical' if critical_count > 0 else 'warning', 'firing')
    
    facts = [
        {"name": "Total Alerts", "value": str(total_alerts)},
        {"name": "Critical", "value": str(critical_count)},
        {"name": "Warning", "value": str(warning_count)}
    ]
    
    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": theme_color,
        "title": "🚨 Prometheus Alert Summary",
        "summary": f"{total_alerts} alerts active",
        "sections": [
            {
                "activityTitle": f"{total_alerts} Alerts Active",
                "activitySubtitle": f"{critical_count} critical, {warning_count} warning",
                "facts": facts
            }
        ]
    }
    
    send_http_request(TEAMS_WEBHOOK_URL, payload)

def send_pagerduty_notifications(alerts, external_url):
    """Send notifications to PagerDuty"""
    for alert in alerts:
        send_pagerduty_individual(alert, external_url)

def send_pagerduty_individual(alert, external_url):
    """Send individual alert to PagerDuty"""
    alert_name = alert.get('labels', {}).get('alertname', 'Unknown Alert')
    severity = alert.get('labels', {}).get('severity', 'unknown')
    status = alert.get('status', 'unknown')
    summary = alert.get('annotations', {}).get('summary', 'No summary available')
    
    # Map Prometheus severity to PagerDuty severity
    pd_severity = PAGERDUTY_SEVERITY_MAP.get(severity, severity)
    
    # Determine event action
    event_action = "resolve" if status == "resolved" else "trigger"
    
    payload = {
        "routing_key": PAGERDUTY_INTEGRATION_KEY,
        "event_action": event_action,
        "dedup_key": f"{alert_name}_{alert.get('labels', {}).get('instance', 'unknown')}",
        "payload": {
            "summary": f"{alert_name}: {summary}",
            "severity": pd_severity,
            "source": alert.get('labels', {}).get('instance', 'unknown'),
            "component": alert.get('labels', {}).get('job', 'prometheus'),
            "group": alert.get('labels', {}).get('alertname', 'prometheus'),
            "class": "prometheus-alert",
            "custom_details": {
                "labels": alert.get('labels', {}),
                "annotations": alert.get('annotations', {}),
                "generator_url": alert.get('generatorURL', ''),
                "external_url": external_url
            }
        }
    }
    
    send_http_request("https://events.pagerduty.com/v2/enqueue", payload)

def send_http_request(url, payload):
    """Send HTTP POST request"""
    try:
        response = http.request(
            'POST',
            url,
            body=json.dumps(payload),
            headers={'Content-Type': 'application/json'}
        )
        print(f"HTTP request sent to {url[:50]}... - Status: {response.status}")
        return response
    except Exception as e:
        print(f"Error sending HTTP request: {str(e)}")
        raise

def send_sns_message(subject, message):
    """Send message to SNS topic"""
    try:
        response = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        print(f"SNS message sent successfully. MessageId: {response['MessageId']}")
        return response
    except Exception as e:
        print(f"Error sending SNS message: {str(e)}")
        raise

def get_alert_emoji(severity, status):
    """Get appropriate emoji for alert"""
    if status == 'resolved':
        return '✅'
    elif severity == 'critical':
        return '🚨'
    elif severity == 'warning':
        return '⚠️'
    elif severity == 'info':
        return 'ℹ️'
    else:
        return '🔔'

def get_slack_color(severity, status):
    """Get Slack attachment color"""
    if status == 'resolved':
        return 'good'
    elif severity == 'critical':
        return 'danger'
    elif severity == 'warning':
        return 'warning'
    else:
        return '#808080'

def get_discord_color(severity, status):
    """Get Discord embed color (decimal)"""
    if status == 'resolved':
        return 3066993  # Green
    elif severity == 'critical':
        return 15158332  # Red
    elif severity == 'warning':
        return 16776960  # Yellow
    else:
        return 8421504  # Gray

def get_teams_color(severity, status):
    """Get Teams theme color (hex)"""
    if status == 'resolved':
        return '2eb886'  # Green
    elif severity == 'critical':
        return 'd63031'  # Red
    elif severity == 'warning':
        return 'fdcb6e'  # Yellow
    else:
        return '636e72'  # Gray

def format_email_alert(alert, external_url):
    """Format individual alert for email"""
    alert_name = alert.get('labels', {}).get('alertname', 'Unknown Alert')
    severity = alert.get('labels', {}).get('severity', 'unknown')
    status = alert.get('status', 'unknown')
    instance = alert.get('labels', {}).get('instance', 'unknown')
    job = alert.get('labels', {}).get('job', 'unknown')
    
    summary = alert.get('annotations', {}).get('summary', 'No summary available')
    description = alert.get('annotations', {}).get('description', 'No description available')
    
    starts_at = format_timestamp(alert.get('startsAt', ''))
    ends_at = format_timestamp(alert.get('endsAt', '')) if alert.get('endsAt') else 'Ongoing'
    
    emoji = get_alert_emoji(severity, status)
    
    return f"""
{emoji} PROMETHEUS ALERT {emoji}

Alert: {alert_name}
Status: {status.upper()}
Severity: {severity.upper()}
Instance: {instance}
Job: {job}

Summary: {summary}
Description: {description}

Timeline:
Started: {starts_at}
Ended: {ends_at}

Labels:
{format_labels(alert.get('labels', {}))}

Annotations:
{format_annotations(alert.get('annotations', {}))}

Generator URL: {alert.get('generatorURL', 'N/A')}
External URL: {external_url}

---
This alert was generated by Amazon Managed Prometheus
Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
"""

def format_email_summary(alerts, external_url):
    """Format alert summary for email"""
    total_alerts = len(alerts)
    critical_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'critical'])
    warning_count = len([a for a in alerts if a.get('labels', {}).get('severity') == 'warning'])
    firing_count = len([a for a in alerts if a.get('status') == 'firing'])
    resolved_count = len([a for a in alerts if a.get('status') == 'resolved'])
    
    message_body = f"""
🚨 PROMETHEUS ALERT SUMMARY 🚨

Total Alerts: {total_alerts}
├── Critical: {critical_count}
├── Warning: {warning_count}
├── Firing: {firing_count}
└── Resolved: {resolved_count}

Individual Alerts:
"""
    
    for i, alert in enumerate(alerts, 1):
        alert_name = alert.get('labels', {}).get('alertname', 'Unknown')
        severity = alert.get('labels', {}).get('severity', 'unknown')
        status = alert.get('status', 'unknown')
        instance = alert.get('labels', {}).get('instance', 'unknown')
        summary = alert.get('annotations', {}).get('summary', 'No summary')
        
        emoji = get_alert_emoji(severity, status)
        message_body += f"""
{i}. {emoji} {alert_name}
   Status: {status.upper()} | Severity: {severity.upper()}
   Instance: {instance}
   Summary: {summary}
"""
    
    message_body += f"""
---
External URL: {external_url}
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
"""
    
    return message_body

def format_timestamp(timestamp_str):
    """Format timestamp string to readable format"""
    if not timestamp_str:
        return 'N/A'
    
    try:
        dt = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d %H:%M:%S UTC')
    except:
        return timestamp_str

def format_labels(labels):
    """Format labels dictionary for display"""
    if not labels:
        return '  (none)'
    
    formatted = ""
    for key, value in labels.items():
        formatted += f"  {key}: {value}\n"
    
    return formatted.rstrip()

def format_annotations(annotations):
    """Format annotations dictionary for display"""
    if not annotations:
        return '  (none)'
    
    formatted = ""
    for key, value in annotations.items():
        formatted += f"  {key}: {value}\n"
    
    return formatted.rstrip()