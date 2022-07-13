variable "container_name" {
  description = "Name of the ECS Container"
  type = string
}

variable "execution_role_arn" {
  description = "ECS IAM Excution Role ARN"
  type = string
}

variable "task_role_arn" {
  description = "ECS IAM Task Role ARN"
  type = string
}

variable "image_uri" {
  description = "The Image URI to use to deploy containers"
  type = string
}

variable "container_port" {
  description = "The ECS container port"
  type = number
}

variable "region" {
  description = "The region to deploy into"
  type        = string
}

# Optional Variables
variable "tags" {
  description = "List of tags to add to resources"
  type = map
  default = {}
}

variable "port_secret_arn" {
  description = "The parameter store port secret arn"
  type = string
  default = ""
}