variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Your name/handle (tagging)"
  type        = string
  default     = "emerson"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "acs-baseline"
}

variable "cw_log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "force_destroy_buckets" {
  description = "If true, allow Terraform to delete non-empty S3 buckets (log/config archives) during destroy. Recommended only for sandbox teardowns."
  type        = bool
  default     = false
}

variable "create_bad_policy_example" {
  description = "If true, create an intentionally bad wildcard IAM policy for demo/remediation evidence (not recommended for baseline deployments)."
  type        = bool
  default     = false
}
