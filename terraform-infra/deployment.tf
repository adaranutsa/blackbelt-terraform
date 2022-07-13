resource "aws_codedeploy_app" "web" {
  compute_platform = "ECS"
  name             = module.ecs_service_web.service_name
}

resource "aws_codedeploy_app" "api" {
  compute_platform = "ECS"
  name             = module.ecs_service_api.service_name
}

resource "aws_codedeploy_deployment_group" "web" {

  app_name               = aws_codedeploy_app.web.name
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  deployment_group_name  = module.ecs_service_web.service_name
  service_role_arn       = module.CodeDeployToECSRole.arn

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE"
    ]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5 # Wait 5 minutes
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = module.ecs_service_web.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [module.ecs_service_web.load_balancer_listener_https_prod_arn]
      }

      target_group {
        name = module.ecs_service_web.load_balancer_target_group_blue_name
      }

      target_group {
        name = module.ecs_service_web.load_balancer_target_group_green_name
      }
    }
  }
}

resource "aws_codedeploy_deployment_group" "api" {

  app_name               = aws_codedeploy_app.api.name
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  deployment_group_name  = module.ecs_service_api.service_name
  service_role_arn       = module.CodeDeployToECSRole.arn

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE"
    ]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5 # Wait 5 minutes
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = module.ecs_service_api.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [module.ecs_service_api.load_balancer_listener_https_prod_arn]
      }

      target_group {
        name = module.ecs_service_api.load_balancer_target_group_blue_name
      }

      target_group {
        name = module.ecs_service_api.load_balancer_target_group_green_name
      }
    }
  }
}

resource "aws_s3_bucket" "s3_artifacts" {
  bucket = "${var.namespace}-deploy-artifacts-${random_string.random.id}"
  tags   = local.common_tags
}

resource "aws_codebuild_project" "s3_artifacts" {
  name          = "S3Artifacts"
  description   = "Grab and output S3 Pipeline artifacts in a file format. This is a workaround."
  build_timeout = "5"
  service_role  = module.CodeBuildToECSRole.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "NO_SOURCE"
    buildspec = jsonencode({
      "version" : "0.2",
      "phases" : {
        "build" : {
          "commands" : [
            "aws s3 sync s3://$ARTIFACTS_BUCKET/$ENV/ ."
          ]
        }
      },
      "artifacts" : {
        "files" : [
          "appspec.yaml",
          "apiTaskDef.json"
        ]
      }
    })
  }
}

resource "aws_s3_bucket" "code_pipeline_artifacts" {
  bucket = "${var.namespace}-codepipeline-artifacts-${random_string.random.id}"
  tags   = local.common_tags
}

resource "aws_codepipeline" "codepipeline_web" {
  name     = "${var.namespace}-DeploymentPipeline-web"
  role_arn = module.codePipelineServiceRole.arn
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.code_pipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "ECR"
      version  = 1
      configuration = {
        RepositoryName = data.terraform_remote_state.cicd.outputs.web_repo_name
        ImageTag       = "latest"
      }
      output_artifacts = ["imageDetailJsonSource"]
    }
  }

  stage {
    name = "S3Source"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        ProjectName = aws_codebuild_project.s3_artifacts.name
        EnvironmentVariables = jsonencode([
          {
            "name" : "ARTIFACTS_BUCKET",
            "value" : aws_s3_bucket.s3_artifacts.bucket,
            "type" : "PLAINTEXT"
          },
          {
            "name" : "ENV",
            "value" : "web",
            "type" : "PLAINTEXT"
          }
        ])
      }
      input_artifacts  = ["imageDetailJsonSource"]
      output_artifacts = ["ArtifactsS3Files"]
    }
  }
  stage {
    name = "Deploy"

    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "CodeDeployToECS"
      version  = 1
      configuration = {
        ApplicationName                = module.ecs_service_web.service_name
        DeploymentGroupName            = aws_codedeploy_deployment_group.web.deployment_group_name
        AppSpecTemplateArtifact        = "ArtifactsS3Files"
        AppSpecTemplatePath            = "appspec.yaml"
        TaskDefinitionTemplatePath     = "apiTaskDef.json"
        TaskDefinitionTemplateArtifact = "ArtifactsS3Files"
        Image1ArtifactName             = "imageDetailJsonSource"
        Image1ContainerName            = "IMAGE1_NAME"

      }
      input_artifacts = ["ArtifactsS3Files", "imageDetailJsonSource"]
    }
  }
}

resource "aws_codepipeline" "codepipeline_api" {
  name     = "${var.namespace}-DeploymentPipeline-api"
  role_arn = module.codePipelineServiceRole.arn
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.code_pipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "ECR"
      version  = 1
      configuration = {
        RepositoryName = data.terraform_remote_state.cicd.outputs.api_repo_name
        ImageTag       = "latest"
      }
      output_artifacts = ["imageDetailJsonSource"]
    }
  }

  stage {
    name = "S3Source"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        ProjectName = aws_codebuild_project.s3_artifacts.name
        EnvironmentVariables = jsonencode([
          {
            "name" : "ARTIFACTS_BUCKET",
            "value" : aws_s3_bucket.s3_artifacts.bucket,
            "type" : "PLAINTEXT"
          },
          {
            "name" : "ENV",
            "value" : "api",
            "type" : "PLAINTEXT"
          }
        ])
      }
      input_artifacts  = ["imageDetailJsonSource"]
      output_artifacts = ["ArtifactsS3Files"]
    }
  }
  stage {
    name = "Deploy"

    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "CodeDeployToECS"
      version  = 1
      configuration = {
        ApplicationName                = module.ecs_service_api.service_name
        DeploymentGroupName            = aws_codedeploy_deployment_group.api.deployment_group_name
        AppSpecTemplateArtifact        = "ArtifactsS3Files"
        AppSpecTemplatePath            = "appspec.yaml"
        TaskDefinitionTemplatePath     = "apiTaskDef.json"
        TaskDefinitionTemplateArtifact = "ArtifactsS3Files"
        Image1ArtifactName             = "imageDetailJsonSource"
        Image1ContainerName            = "IMAGE1_NAME"

      }
      input_artifacts = ["ArtifactsS3Files", "imageDetailJsonSource"]
    }
  }
}

resource "aws_s3_object" "api_task_def_web" {
  bucket = aws_s3_bucket.s3_artifacts.bucket
  key    = "web/apiTaskDef.json"
  content = templatefile("templates/web_task_definition.tftpl", {
    executionRoleArn  = module.ecsTaskExecutionRole_web.arn,
    taskRoleArn       = module.ecsTaskRole_web.arn,
    servicePort       = 80,
    cpu               = 256,
    memory            = 512,
    memoryReservation = 256,
    containerName     = "${var.namespace}WebContainer",
    family            = "${var.namespace}WebContainer",
    region            = var.region
  })
}

resource "aws_s3_object" "appspec_web" {
  bucket = aws_s3_bucket.s3_artifacts.bucket
  key    = "web/appspec.yaml"
  content = templatefile("templates/appspec.tftpl", {
    servicePort   = 80,
    containerName = "${var.namespace}WebContainer"
  })
}

resource "aws_s3_object" "api_task_def_api" {
  bucket = aws_s3_bucket.s3_artifacts.bucket
  key    = "api/apiTaskDef.json"
  content = templatefile("templates/api_task_definition.tftpl", {
    executionRoleArn  = module.ecsTaskExecutionRole_api.arn,
    taskRoleArn       = module.ecsTaskRole_api.arn,
    servicePort       = 80,
    cpu               = 256,
    memory            = 512,
    memoryReservation = 256,
    containerName     = "${var.namespace}ApiContainer",
    family            = "${var.namespace}ApiContainer",
    region            = var.region
    portSecret        = data.aws_ssm_parameter.api_port.arn
  })
}

resource "aws_s3_object" "appspec_api" {
  bucket = aws_s3_bucket.s3_artifacts.bucket
  key    = "api/appspec.yaml"
  content = templatefile("templates/appspec.tftpl", {
    servicePort   = 80,
    containerName = "${var.namespace}ApiContainer"
  })
}

resource "aws_cloudwatch_event_rule" "ecr_push_web" {
  name        = "${var.namespace}-${var.environment}-codepipeline-trigger-rule-web"
  description = "Detect images pushes to ECR repo and triggers CodePipeline."

  event_pattern = <<PATTERN
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": {
    "action-type": ["PUSH"],
    "result": ["SUCCESS"],
    "repository-name": ["${data.terraform_remote_state.cicd.outputs.web_repo_name}"],
    "image-tag": ["latest"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "ecr_push_web" {
  target_id = "${var.namespace}-${var.environment}-codepipeline-trigger-target-web"
  rule      = aws_cloudwatch_event_rule.ecr_push_web.name
  arn       = aws_codepipeline.codepipeline_web.arn
  role_arn  = module.EventRuleECRRole.arn
}

resource "aws_cloudwatch_event_rule" "ecr_push_api" {
  name        = "${var.namespace}-${var.environment}-codepipeline-trigger-rule-api"
  description = "Detect images pushes to ECR repo and triggers CodePipeline."

  event_pattern = <<PATTERN
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": {
    "action-type": ["PUSH"],
    "result": ["SUCCESS"],
    "repository-name": ["${data.terraform_remote_state.cicd.outputs.api_repo_name}"],
    "image-tag": ["latest"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "ecr_push_api" {
  target_id = "${var.namespace}-${var.environment}-codepipeline-trigger-target-api"
  rule      = aws_cloudwatch_event_rule.ecr_push_api.name
  arn       = aws_codepipeline.codepipeline_api.arn
  role_arn  = module.EventRuleECRRole.arn
}