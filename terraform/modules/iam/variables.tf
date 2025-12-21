variable "name_prefix" {
  description = "Prefix for IAM resources"
  type        = string
}

variable "create_bad_policy_example" {
  description = "If true, create an intentionally bad wildcard IAM policy for demo/remediation evidence."
  type        = bool
  default     = false
}
