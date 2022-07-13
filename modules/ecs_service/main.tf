resource "aws_ecs_service" "main" {
  name                    = "${var.namespace}-${var.service_name}"
  cluster                 = var.cluster_arn
  task_definition         = var.task_definition_arn
  desired_count           = var.desired_count
  enable_ecs_managed_tags = true

  health_check_grace_period_seconds = 120

  propagate_tags                     = var.propagate_tags
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy

    content {
      capacity_provider = capacity_provider_strategy.value.provider
      base              = capacity_provider_strategy.value.base
      weight            = capacity_provider_strategy.value.weight
    }

  }

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = var.internal_security_groups
    assign_public_ip = false
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes        = [desired_count, task_definition]
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 5
  min_capacity       = var.desired_count
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "scale-down"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70
    scale_in_cooldown  = 600
    scale_out_cooldown = 180

    customized_metric_specification {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      statistic   = "Average"
      unit        = "Percent"
    }
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_id
}