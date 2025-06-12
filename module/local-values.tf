locals {
  owners = var.business_division
  environment = var.environment
  project_name = var.project_name
  # # The name of the project, environment, and business division are combined to create a unique name for the resources
  # This is useful for identifying resources in the AWS console and for tagging purposes
  name = "${var.project_name}-${var.environment}-${var.business_division}"


# # Common tags for all resources
  # This is a map of tags that will be applied to all resources created in this module
  common_tags = {
    Name        = local.owners
    Environment = local.environment
    Project     = local.project_name

  }
}