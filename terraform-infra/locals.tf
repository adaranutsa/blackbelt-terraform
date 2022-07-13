locals {
  common_tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  cluster_name = "${var.namespace}-${var.environment}-cluster"

  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}