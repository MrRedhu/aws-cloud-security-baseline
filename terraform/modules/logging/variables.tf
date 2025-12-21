variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cw_log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}
