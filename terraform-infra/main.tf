resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

data "aws_iam_policy_document" "allow_alb_logging" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["127311923021"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.logs.arn}/*",
    ]
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${lower(var.namespace)}-${lower(var.environment)}-logs-${random_string.random.id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.allow_alb_logging.json
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  rule {
    id     = "expire_old_artifacts"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}