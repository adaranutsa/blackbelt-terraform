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

variable "github_repo_web_id" {
  description = "Github repository and owner. Example: user/repo"
  type        = string
}

variable "github_repo_api_id" {
  description = "Github repository and owner. Example: user/repo"
  type        = string
}

variable "github_codestar_name" {
  description = "The CodeStart GitHub Connection Name (Must already exist)"
  type        = string
  default     = "GitHub"
}