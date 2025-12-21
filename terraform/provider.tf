provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "aws-cloud-security-baseline"
      Env     = var.env
      Owner   = var.owner
    }
  }
}
