module "codePipelineServiceRole" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-CodePipelineServiceRole"
  description           = "Allows CodePipeline to call AWS services on your behalf."
  assume_role_principal = "codepipeline"
  inline_policies = [{
    name   = "CodePipelineServicePolicy"
    policy = data.aws_iam_policy_document.CodePipelineServicePolicy.json
  }]

  managed_policies = [
    "AWSCodeDeployFullAccess",
    "AmazonS3FullAccess",
    "AWSCodeBuildDeveloperAccess"
  ]
}

module "codeBuildRole" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-codeBuildRole"
  description           = "Allows CodeBuild to call AWS services on your behalf."
  assume_role_principal = "codebuild"
  inline_policies = [{
    name   = "codeBuildRolePolicy"
    policy = data.aws_iam_policy_document.CodeBuildServicePolicy.json
  }]

  managed_policies = [
    "AWSCodeDeployFullAccess",
    "AmazonS3FullAccess",
    "AWSCodeBuildDeveloperAccess"
  ]
}