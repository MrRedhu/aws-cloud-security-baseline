output "admin_role_arn" {
  value = aws_iam_role.admin.arn
}

output "developer_role_arn" {
  value = aws_iam_role.developer.arn
}

output "readonly_role_arn" {
  value = aws_iam_role.readonly.arn
}

output "bad_policy_arn" {
  value = aws_iam_policy.bad_wildcard.arn
}

output "fixed_policy_arn" {
  value = aws_iam_policy.fixed_dev.arn
}
