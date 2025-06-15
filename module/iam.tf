# IAM Role for Prometheus workspace
resource "aws_iam_role" "prometheus_role" {
  name = "${var.workspace_name}-prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "aps.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.workspace_name}-prometheus-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for Prometheus workspace
resource "aws_iam_role_policy" "prometheus_policy" {
  name = "${var.workspace_name}-prometheus-policy"
  role = aws_iam_role.prometheus_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.prometheus.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = var.enable_logging ? "${aws_cloudwatch_log_group.prometheus_logs[0].arn}:*" : "*"
      }
    ]
  })
}

# IAM Role for EC2 instances to send metrics
resource "aws_iam_role" "prometheus_ec2_role" {
  name = "${var.workspace_name}-ec2-prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.workspace_name}-ec2-prometheus-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for EC2 to write to Prometheus
resource "aws_iam_role_policy" "prometheus_ec2_policy" {
  name = "${var.workspace_name}-ec2-prometheus-policy"
  role = aws_iam_role.prometheus_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite"
        ]
        Resource = aws_prometheus_workspace.prometheus.arn
      }
    ]
  })
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "prometheus_ec2_profile" {
  name = "${var.workspace_name}-ec2-prometheus-profile"
  role = aws_iam_role.prometheus_ec2_role.name

  tags = {
    Name        = "${var.workspace_name}-ec2-prometheus-profile"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Lambda webhook function
resource "aws_iam_role" "lambda_webhook_role" {
  count = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  name  = "${var.workspace_name}-lambda-webhook-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.workspace_name}-lambda-webhook-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for Lambda to publish to SNS (only if email notifications enabled)
resource "aws_iam_role_policy" "lambda_webhook_sns_policy" {
  count = var.create_lambda_webhook && local.notification_channels.email.enabled ? 1 : 0
  name  = "${var.workspace_name}-lambda-webhook-sns-policy"
  role  = aws_iam_role.lambda_webhook_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.prometheus_alerts[0].arn
      }
    ]
  })
}

# Attach basic execution role to Lambda
resource "aws_iam_role_policy_attachment" "lambda_webhook_policy" {
  count      = var.create_lambda_webhook && local.any_notifications_enabled ? 1 : 0
  role       = aws_iam_role.lambda_webhook_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  count = var.create_oidc_role ? 1 : 0

  name        = "GitHubActions-Terraform-Role"
  description = "Role for GitHub Actions to deploy Terraform infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "GitHubActions-Terraform-Role"
    Purpose    = "GitHub Actions OIDC role"
    Repository = "${var.github_username}/${var.github_repository}"
  }
}

# IAM Policy for Terraform operations
resource "aws_iam_policy" "github_actions_terraform" {
  count = var.create_oidc_role ? 1 : 0

  name        = "GitHubActions-Terraform-Policy"
  description = "Policy for GitHub Actions Terraform operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Prometheus permissions
          "aps:*",

          # SNS permissions
          "sns:*",

          # Lambda permissions
          "lambda:*",

          # IAM permissions (for creating roles and policies)
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:PassRole",
          "iam:GetRole",
          "iam:GetInstanceProfile",
          "iam:GetPolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:TagInstanceProfile",

          # CloudWatch Logs permissions
          "logs:*",

          # S3 permissions (for Terraform state)
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",

          # DynamoDB permissions (for Terraform state locking)
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name       = "GitHubActions-Terraform-Policy"
    Purpose    = "GitHub Actions Terraform permissions"
    Repository = "${var.github_username}/${var.github_repository}"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  count = var.create_oidc_role ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions_terraform[0].arn
}