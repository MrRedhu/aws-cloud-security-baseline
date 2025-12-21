output "admin_role_arn" {
  value = module.iam.admin_role_arn
}

output "developer_role_arn" {
  value = module.iam.developer_role_arn
}

output "readonly_role_arn" {
  value = module.iam.readonly_role_arn
}

output "bad_policy_arn" {
  value = module.iam.bad_policy_arn
}

output "fixed_policy_arn" {
  value = module.iam.fixed_policy_arn
}
