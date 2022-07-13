resource "aws_lb" "main" {
  name               = "${local.lb_name_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.external_security_groups
  subnets            = var.public_subnets

  enable_deletion_protection = false

  access_logs {
    bucket  = var.logs_bucket
    prefix  = "${local.lb_name_prefix}-lb"
    enabled = true
  }

  tags = var.tags
}

resource "aws_lb_target_group" "blue" {
  name        = "${local.lb_name_prefix}-lb-tg-blue"
  port        = var.container_port
  protocol    = var.container_protocol
  target_type = "ip"
  vpc_id      = var.vpc_id

  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    enabled           = true
    healthy_threshold = 5
    path              = var.lb_health_check_path
    protocol          = var.container_protocol
    matcher           = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${local.lb_name_prefix}-lb-tg-green"
  port        = var.container_port
  protocol    = var.container_protocol
  target_type = "ip"
  vpc_id      = var.vpc_id

  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    enabled           = true
    healthy_threshold = 5
    path              = var.lb_health_check_path
    protocol          = var.container_protocol
    matcher           = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "https_prod" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.external_lb_port
  protocol          = var.external_lb_protocol
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 1
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }

      stickiness {
        duration = 86400
        enabled  = true
      }
    }
  }

  depends_on = [
    aws_lb_target_group.blue,
    aws_lb_target_group.green
  ]
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "api_record_A" {
  allow_overwrite = true
  name            = var.domain_name
  type            = "A"
  zone_id         = data.aws_route53_zone.main.zone_id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_record_AAAA" {
  allow_overwrite = true
  name            = var.domain_name
  type            = "AAAA"
  zone_id         = data.aws_route53_zone.main.zone_id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
