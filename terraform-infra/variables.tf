# Required Variables
variable "namespace" {
  description = "The namespace prefix to add to all resources"
  type        = string
}

variable "region" {
  description = "The region to deploy into"
  type        = string
}

variable "environment" {
  description = "The environment name. E.g. production"
  type        = string
}

variable "domain" {
  description = "The apex domain name for the application"
  type        = string
}

# Optional Variables
variable "vpc_cidr" {
  description = "The VPC CIDR to use. Default is 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}
