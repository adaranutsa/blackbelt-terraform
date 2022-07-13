output "arn" {
  value = aws_ecs_task_definition.main.arn
}

output "family" {
  value = aws_ecs_task_definition.main.family
}