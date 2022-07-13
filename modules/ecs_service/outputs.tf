output "service_id" {
  value = aws_ecs_service.main.id
}

output "service_name" {
  value = aws_ecs_service.main.name
}

output "service_cluster" {
  value = aws_ecs_service.main.cluster
}

output "service_desired_count" {
  value = aws_ecs_service.main.desired_count
}

output "acm_cert_arn" {
  value = aws_acm_certificate.main.arn
}

output "load_balancer_arn" {
  value = aws_lb.main.arn
}

output "load_balancer_target_group_blue_arn" {
  value = aws_lb_target_group.blue.arn
}

output "load_balancer_target_group_green_arn" {
  value = aws_lb_target_group.green.arn
}

output "load_balancer_target_group_blue_name" {
  value = aws_lb_target_group.blue.name
}

output "load_balancer_target_group_green_name" {
  value = aws_lb_target_group.green.name
}

output "load_balancer_listener_https_prod_arn" {
  value = aws_lb_listener.https_prod.arn
}