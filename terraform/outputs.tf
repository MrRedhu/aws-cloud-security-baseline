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

output "log_bucket_name" {
  value = module.logging.log_bucket_name
}

output "cloudtrail_name" {
  value = module.logging.cloudtrail_name
}

output "cloudtrail_log_group" {
  value = module.logging.cloudtrail_log_group
}

output "vpc_flow_log_group" {
  value = module.logging.vpc_flow_log_group
}

output "flowlogs_vpc_id" {
  value = module.logging.flowlogs_vpc_id
}

output "guardduty_detector_id" {
  value = module.detection.guardduty_detector_id
}

output "securityhub_enabled" {
  value = module.detection.securityhub_enabled
}
