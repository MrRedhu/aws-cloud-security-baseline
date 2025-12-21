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
