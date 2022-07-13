#####################
#    ECS Cluster    #
#####################

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name
  tags = merge(
    local.common_tags,
    {
      Name = local.cluster_name
    }
  )
}

# Allows us to use FARGATE for base load with a minimum of 2 containers and FARGATE_SPOT for auto scaling
# where 40% of new containers come online as base load running on FARGATE and 60% of containers (after base load is met)
# come online running on FARGATE_SPOT
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 2
    weight            = 40
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    base              = 0
    weight            = 60
    capacity_provider = "FARGATE_SPOT"
  }
}

######################
#    ECS Task Def    #
######################

module "task_definition_web" {
  source = "../modules/ecs_task_definition"

  container_name     = "${var.namespace}WebContainer"
  execution_role_arn = module.ecsTaskExecutionRole_web.arn
  task_role_arn      = module.ecsTaskRole_web.arn
  image_uri          = "${data.terraform_remote_state.cicd.outputs.web_repo_url}:latest"
  container_port     = 80
  region             = var.region
  tags               = local.common_tags
}

module "task_definition_api" {
  source = "../modules/ecs_task_definition"

  container_name     = "${var.namespace}ApiContainer"
  execution_role_arn = module.ecsTaskExecutionRole_api.arn
  task_role_arn      = module.ecsTaskRole_api.arn
  image_uri          = "${data.terraform_remote_state.cicd.outputs.api_repo_url}:latest"
  container_port     = data.aws_ssm_parameter.api_port.value
  port_secret_arn    = data.aws_ssm_parameter.api_port.arn
  region             = var.region
  tags               = local.common_tags
}

######################
#    ECS Services    #
######################

module "ecs_service_web" {
  source = "../modules/ecs_service"

  namespace                = var.namespace
  service_name             = "web-service-a"
  container_name           = module.task_definition_web.family
  cluster_arn              = aws_ecs_cluster.main.arn
  task_definition_arn      = module.task_definition_web.arn
  private_subnets          = module.vpc.private_subnets
  public_subnets           = module.vpc.public_subnets
  vpc_id                   = module.vpc.vpc_id
  internal_security_groups = [module.internal_sg_web.id]
  external_security_groups = [module.external_sg_web.id]
  domain_zone              = var.domain
  domain_name              = var.domain
  waf_id                   = module.regional_waf.web_acl_id
  logs_bucket              = aws_s3_bucket.logs.id

  desired_count = 2
  tags          = local.common_tags
}

module "ecs_service_api" {
  source = "../modules/ecs_service"

  namespace                = var.namespace
  service_name             = "api-service-a"
  container_name           = module.task_definition_api.family
  cluster_arn              = aws_ecs_cluster.main.arn
  task_definition_arn      = module.task_definition_api.arn
  private_subnets          = module.vpc.private_subnets
  public_subnets           = module.vpc.public_subnets
  vpc_id                   = module.vpc.vpc_id
  internal_security_groups = [module.internal_sg_api.id]
  external_security_groups = [module.external_sg_api.id]
  domain_zone              = var.domain
  domain_name              = "api.${var.domain}"
  waf_id                   = module.regional_waf.web_acl_id
  logs_bucket              = aws_s3_bucket.logs.id

  desired_count = 2
  tags          = local.common_tags
}
