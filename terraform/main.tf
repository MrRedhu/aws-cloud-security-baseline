module "iam" {
  source      = "./modules/iam"
  name_prefix = var.name_prefix
}

module "logging" {
  source                = "./modules/logging"
  name_prefix           = var.name_prefix
  cw_log_retention_days = var.cw_log_retention_days
}
