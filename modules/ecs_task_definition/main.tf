locals {
  secrets = [{
    name = "BB_API_PORT",
    valueFrom = var.port_secret_arn
  }]
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.container_name
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    # Application Container
    {
      name       = var.container_name
      image      = var.image_uri
      essential  = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ],
      secrets = var.port_secret_arn != "" ? local.secrets : null
      logConfiguration = {
        logDriver = "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.container_name}",
          "awslogs-region": var.region,
          "awslogs-create-group": "true",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ])
  tags = var.tags
}