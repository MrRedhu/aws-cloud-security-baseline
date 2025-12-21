data "aws_region" "current" {}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true
}

# Security Hub
resource "aws_securityhub_account" "main" {}

# Enable the foundational standard (commonly expected)
resource "aws_securityhub_standards_subscription" "foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.id}::standards/aws-foundational-security-best-practices/v/1.0.0"
}
