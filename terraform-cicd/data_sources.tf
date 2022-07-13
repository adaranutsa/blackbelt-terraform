data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_codestarconnections_connection" "github" {
  name = var.github_codestar_name
}

data "aws_iam_policy_document" "CodePipelineServicePolicy" {
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"

      values = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
  statement {
    actions = [
      "cloudwatch:*",
      "ecs:*",
      "lambda:InvokeFunction",
      "lambda:ListFunctions",
      "ecr:*",
      "s3:*",
      "codestar-connections:Get*",
      "codestar-connections:List*",
      "codestar-connections:Use*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "CodeBuildServicePolicy" {
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"

      values = [
        "codebuild.amazonaws.com"
      ]
    }
  }
  statement {
    actions = [
      "cloudwatch:*",
      "logs:*",
      "ecr:*"
    ]
    resources = ["*"]
  }
}