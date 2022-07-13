resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

module "ecr_web" {
  source               = "lgallard/ecr/aws"
  version              = "0.3.2"
  name                 = "${lower(var.namespace)}-web-repo"
  tags                 = local.common_tags
  scan_on_push         = true
  timeouts_delete      = "60m"
  image_tag_mutability = "MUTABLE"

  lifecycle_policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 1 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 2 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 2
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

module "ecr_api" {
  source               = "lgallard/ecr/aws"
  version              = "0.3.2"
  name                 = "${lower(var.namespace)}-api-repo"
  tags                 = local.common_tags
  scan_on_push         = true
  timeouts_delete      = "60m"
  image_tag_mutability = "MUTABLE"

  lifecycle_policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 1 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last 2 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 2
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}