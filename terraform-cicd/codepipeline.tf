resource "aws_s3_bucket" "code_pipeline_artifacts" {
  bucket = "${var.namespace}-codepipeline-artifacts-${random_string.random.id}"
  tags   = local.common_tags
}

resource "aws_codebuild_project" "web" {
  name          = "${var.namespace}-web-project"
  build_timeout = "5"
  service_role  = module.codeBuildRole.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = module.ecr_web.repository_url
    }

    environment_variable {
      name  = "PROJECT_FOLDER"
      value = "web"
    }

    environment_variable {
      name  = "REGION"
      value = local.region
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.common_tags
}

resource "aws_codebuild_project" "api" {
  name          = "${var.namespace}-api-project"
  build_timeout = "5"
  service_role  = module.codeBuildRole.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = module.ecr_api.repository_url
    }

    environment_variable {
      name  = "PROJECT_FOLDER"
      value = "api"
    }

    environment_variable {
      name  = "REGION"
      value = local.region
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.common_tags
}

resource "aws_codepipeline" "web" {
  name     = "${var.namespace}-build-pipeline-web"
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
      provider = "CodeStarSourceConnection"
      version  = 1
      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo_web_id
        BranchName       = "main"
      }
      output_artifacts = ["SourceOutput"]
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        ProjectName = aws_codebuild_project.web.id
      }
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
    }
  }
}

resource "aws_codepipeline" "api" {
  name     = "${var.namespace}-build-pipeline-api"
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
      provider = "CodeStarSourceConnection"
      version  = 1
      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo_api_id
        BranchName       = "main"
      }
      output_artifacts = ["SourceOutput"]
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        ProjectName = aws_codebuild_project.api.id
      }
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
    }
  }
}