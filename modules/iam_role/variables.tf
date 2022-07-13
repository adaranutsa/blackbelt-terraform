# Required variables
variable "name" {
  description = "IAM Role Name"
  type        = string
}

variable "assume_role_principal" {
  description = "IAM Role Principal/Service Identifier. E.g. lambda, ecs-tasks"
  type        = string
}

# Optional variables
variable "description" {
  description = "IAM Role Description"
  type        = string
  default     = ""
}

variable "managed_policies" {
  description = "List of AWS Managed Policy Names to add to the role."
  type        = list(any)
  default     = []
}

variable "inline_policies" {
  description = "List of inline policies to add."
  type        = list(any)
  default     = []
}