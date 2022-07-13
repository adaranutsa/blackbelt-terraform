# Required Variables
variable "service_name" {
  description = "(Required) The name of the service (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
}

variable "namespace" {
  description = "A namespace to prefix to all environment resources"
  type        = string
}

variable "cluster_arn" {
  description = "(Required) ARN of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "(Required) The family and revision (family:revision) or full ARN of the task definition that you want to run in your service."
  type        = string
}

variable "private_subnets" {
  description = "(Required) The private subnets associated with the task or service."
  type        = list(any)
}

variable "public_subnets" {
  description = "(Required) The public subnets associated with the load balancer"
  type        = list(any)
  default     = null
}

variable "internal_security_groups" {
  description = "(Required) The internal security groups associated with the task or service."
  type        = list(any)
}

variable "external_security_groups" {
  description = "(Optional) The external security groups associated with the load balancer."
  type        = list(any)
}

variable "vpc_id" {
  description = "(Required) The VPC ID to deploy this service into."
  type        = string
}

variable "domain_zone" {
  description = "(Required) The apex domain name"
  type        = string
}

variable "domain_name" {
  description = "(Required) The domain name for the service"
  type        = string
}

variable "container_name" {
  description = "(Required) The Task Definition container name"
  type        = string
}

variable "waf_id" {
  description = "(Required) The Regional WAF ID to associate with the Load Balancer"
  type        = string
}

variable "logs_bucket" {
  description = "(Required) The S3 Logs Bucket name to store logs"
  type        = string
}

# Optional Variables

variable "lb_health_check_path" {
  description = "(Optional) The target group health check path."
  type        = string
  default     = "/"
}

variable "desired_count" {
  description = "(Optional) The number of instances of the task definition to place and keep running. Defaults to 0. Do not specify if using the DAEMON scheduling strategy."
  type        = number
  default     = 0
}

variable "capacity_provider_strategy" {
  description = "(Optional) Capacity provider strategies to use for the service. Can be one or more. These can be updated without destroying and recreating the service only if force_new_deployment = true and not changing from 0 capacity_provider_strategy blocks to greater than 0, or vice versa. See below."
  type        = map
  default = {
    fargate = {
      provider = "FARGATE"
      base     = 2
      weight   = 40
    },
    fargate_spot = {
      provider = "FARGATE_SPOT"
      base     = 0
      weight   = 60
    }
  }
}

variable "propagate_tags" {
  description = "(Optional) Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION. Defaults to SERVICE."
  type        = string
  default     = "SERVICE"
}

variable "deployment_minimum_healthy_percent" {
  description = "(Optional) The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. Defaults to 100."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "(Optional) The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the DAEMON scheduling strategy. Defaults to 200."
  type        = number
  default     = 200
} 

variable "tags" {
  description = "(Optional) Key-value mapping of resource tags"
  type        = map(any)
  default     = {}
}

variable "container_port" {
  description = "The container port to use."
  default     = 80
  type        = number
}

variable "container_protocol" {
  description = "The container port to use."
  default     = "HTTP"
  type        = string
}

variable "external_lb_port" {
  description = "The external load balancer port"
  default     = 443
  type        = number
}

variable "external_lb_protocol" {
  description = "The external load balancer port"
  default     = "HTTPS"
  type        = string
}
