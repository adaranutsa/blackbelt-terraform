data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "cicd" {
  backend = "local"

  config = {
    path = "../terraform-cicd/terraform.tfstate"
  }
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
      "s3:*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "TriggerCodePipelinePolicy" {
  statement {
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = ["arn:aws:codepipeline:${local.region}:${local.account_id}:${var.namespace}-DeploymentPipeline-*"]
  }
}

data "aws_ssm_parameter" "api_port" {
  name = "/api/port"
}