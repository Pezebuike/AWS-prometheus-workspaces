# GitHub OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_role ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name       = "github-actions-oidc"
    Purpose    = "GitHub Actions OIDC authentication"
    Repository = "${var.github_username}/${var.github_repository}"
  }
}






