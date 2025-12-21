module "iam" {
  source      = "./modules/iam"
  name_prefix = var.name_prefix
}
