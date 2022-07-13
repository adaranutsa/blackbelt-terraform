variable "name" {
  description = "Security group name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID inside where to create the security group"
  type        = string
}

variable "rules_cidr" {
  description = "List of rules with CIDR Blocks as the source"
  type        = list(any)
  default     = []
}


variable "rules_sgsource" {
  description = "List of rules with SG ID as the source"
  type        = list(any)
  default     = []
}