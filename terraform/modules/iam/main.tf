data "aws_caller_identity" "current" {}

# Trust policy: allow the same account to assume these roles (demo-friendly)
# In real orgs, you'd restrict to specific IAM principals / SSO.
locals {
  assume_role_trust = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "admin" {
  name               = "${var.name_prefix}-admin-role"
  assume_role_policy = local.assume_role_trust
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "readonly" {
  name               = "${var.name_prefix}-readonly-role"
  assume_role_policy = local.assume_role_trust
}

resource "aws_iam_role_policy_attachment" "readonly_attach" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "developer" {
  name               = "${var.name_prefix}-developer-role"
  assume_role_policy = local.assume_role_trust
}

# --- BAD POLICY (for before/after evidence) ---
resource "aws_iam_policy" "bad_wildcard" {
  count = var.create_bad_policy_example ? 1 : 0

  name        = "${var.name_prefix}-dev-bad-wildcard"
  description = "Intentionally bad policy for portfolio evidence: allow * on * (do not keep attached)."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid      = "BadWildcard",
      Effect   = "Allow",
      Action   = "*",
      Resource = "*"
    }]
  })
}

# --- FIXED POLICY (least privilege example) ---
# This example allows basic read-only describe/list actions, CloudWatch Logs read, and S3 read on a named bucket placeholder.
# We'll tighten this further once logging resources exist (so we can scope ARNs precisely).
resource "aws_iam_policy" "fixed_dev" {
  name        = "${var.name_prefix}-dev-fixed"
  description = "Least-privilege developer policy (portfolio baseline)."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowDescribeList",
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "s3:ListAllMyBuckets",
          "cloudtrail:Describe*",
          "cloudtrail:Get*",
          "guardduty:List*",
          "guardduty:Get*",
          "securityhub:Get*",
          "securityhub:Describe*",
          "securityhub:List*"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsRead",
        Effect = "Allow",
        Action = [
          "logs:Describe*",
          "logs:Get*",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ],
        Resource = "*"
      },
      {
        Sid    = "DenyIAMWrites",
        Effect = "Deny",
        Action = [
          "iam:*",
          "organizations:*",
          "account:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# ATTACHMENT SWITCH:
# The baseline attaches the FIXED policy by default.
# The BAD policy is created only when var.create_bad_policy_example is enabled (demo-only; do not attach in real environments).
resource "aws_iam_role_policy_attachment" "dev_policy_attach" {
  role       = aws_iam_role.developer.name
  policy_arn = aws_iam_policy.fixed_dev.arn
}
