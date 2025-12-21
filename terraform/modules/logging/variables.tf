variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cw_log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "force_destroy_buckets" {
  description = "If true, allow Terraform to delete the log archive bucket even if it contains objects (sandbox teardown helper)."
  type        = bool
  default     = false
}
