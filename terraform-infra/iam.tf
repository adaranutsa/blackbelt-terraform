module "ecsTaskExecutionRole_web" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-ecsTaskExecutionRole-web"
  description           = "Role used for ECS Container execution"
  assume_role_principal = "ecs-tasks"
  managed_policies = [
    "service-role/AmazonECSTaskExecutionRolePolicy",
    "AmazonSSMFullAccess"
  ]
}

module "ecsTaskRole_web" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-ecsTaskRole-web"
  description           = "Allows ECS tasks to call AWS services on your behalf."
  assume_role_principal = "ecs-tasks"
  managed_policies = [
    "AmazonSSMFullAccess"
  ]
}

module "ecsTaskExecutionRole_api" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-ecsTaskExecutionRole-api"
  description           = "Role used for ECS Container execution"
  assume_role_principal = "ecs-tasks"
  managed_policies = [
    "service-role/AmazonECSTaskExecutionRolePolicy",
    "AmazonSSMFullAccess"
  ]
}

module "ecsTaskRole_api" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-ecsTaskRole-api"
  description           = "Allows ECS tasks to call AWS services on your behalf."
  assume_role_principal = "ecs-tasks"
  managed_policies = [
    "AmazonSSMFullAccess"
  ]
}

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

module "TransformImageDetailsRole" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-TransformImageDetails-LambdaRole"
  description           = "Allows Lambda to call AWS services on your behalf."
  assume_role_principal = "lambda"
  managed_policies = [
    "service-role/AWSLambdaBasicExecutionRole",
    "AWSCodePipelineFullAccess",
    "AmazonS3FullAccess"
  ]
}

module "CodeDeployToECSRole" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-CodeDeployToECS"
  description           = "Allows CodeDeploy to deploy to ECS"
  assume_role_principal = "codedeploy"
  managed_policies = [
    "AWSCodeDeployRoleForECS"
  ]
}

module "CodeBuildToECSRole" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-CodeBuildECS"
  description           = "Allows CodeBuild to run in CodePipeline to deploy to ECS"
  assume_role_principal = "codebuild"
  managed_policies = [
    "PowerUserAccess"
  ]
}

module "EventRuleECRRole" {
  source                = "../modules/iam_role"
  name                  = "${var.namespace}-EventRuleECRRole"
  description           = "Allows Event Rule to trigger CodePipeline."
  assume_role_principal = "events"
  inline_policies = [{
    name   = "start-pipeline-execution",
    policy = data.aws_iam_policy_document.TriggerCodePipelinePolicy.json
  }]
}