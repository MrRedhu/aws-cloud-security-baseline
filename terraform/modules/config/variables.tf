variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "force_destroy_buckets" {
  description = "If true, allow Terraform to delete the Config archive bucket even if it contains objects (sandbox teardown helper)."
  type        = bool
  default     = false
}
