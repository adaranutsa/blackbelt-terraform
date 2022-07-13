locals {
  common_tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  region = data.aws_region.current.name
}