module "iam" {
  source                    = "./modules/iam"
  name_prefix               = var.name_prefix
  create_bad_policy_example = var.create_bad_policy_example
}

module "logging" {
  source                = "./modules/logging"
  name_prefix           = var.name_prefix
  cw_log_retention_days = var.cw_log_retention_days
  force_destroy_buckets = var.force_destroy_buckets
}

module "config" {
  source                = "./modules/config"
  name_prefix           = var.name_prefix
  force_destroy_buckets = var.force_destroy_buckets
}

module "detection" {
  source      = "./modules/detection"
  name_prefix = var.name_prefix
}
