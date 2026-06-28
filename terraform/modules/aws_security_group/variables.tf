variable "vpc_id" {
  description = "ID of the VPC where the security group will be created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must be a non-empty string."
  }
}

variable "security_group_name" {
  description = "Name of the security group. Used as the Name and resource identifier."
  type        = string

  validation {
    condition     = length(trimspace(var.security_group_name)) > 0
    error_message = "security_group_name must be a non-empty string."
  }
}

variable "description" {
  description = "Description applied to the security group resource."
  type        = string
  default     = "Managed by Terraform"
}

variable "ingress_rules" {
  description = <<-EOT
    Map of ingress (inbound) rules. The map key is an arbitrary, stable
    identifier for the rule (used to keep plans deterministic). Each rule must
    define exactly one traffic source: cidr_blocks, ipv6_cidr_blocks,
    prefix_list_ids, or referenced_security_group_id.
  EOT
  type = map(object({
    description                  = string
    from_port                    = number
    to_port                      = number
    protocol                     = optional(string, "tcp")
    cidr_blocks                  = optional(list(string))
    ipv6_cidr_blocks             = optional(list(string))
    prefix_list_ids              = optional(list(string))
    referenced_security_group_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      (rule.cidr_blocks != null ? 1 : 0) +
      (rule.ipv6_cidr_blocks != null ? 1 : 0) +
      (rule.prefix_list_ids != null ? 1 : 0) +
      (rule.referenced_security_group_id != null ? 1 : 0) == 1
    ])
    error_message = "Each ingress rule must specify exactly one traffic source: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, or referenced_security_group_id."
  }

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      rule.from_port >= -1 && rule.from_port <= 65535 &&
      rule.to_port >= -1 && rule.to_port <= 65535 &&
      rule.from_port <= rule.to_port
    ])
    error_message = "Each ingress rule must have from_port and to_port between -1 and 65535, with from_port <= to_port."
  }
}

variable "egress_rules" {
  description = <<-EOT
    Map of egress (outbound) rules. The map key is an arbitrary, stable
    identifier for the rule. Each rule must define exactly one traffic
    destination: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, or
    referenced_security_group_id.
  EOT
  type = map(object({
    description                  = string
    from_port                    = number
    to_port                      = number
    protocol                     = optional(string, "tcp")
    cidr_blocks                  = optional(list(string))
    ipv6_cidr_blocks             = optional(list(string))
    prefix_list_ids              = optional(list(string))
    referenced_security_group_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      (rule.cidr_blocks != null ? 1 : 0) +
      (rule.ipv6_cidr_blocks != null ? 1 : 0) +
      (rule.prefix_list_ids != null ? 1 : 0) +
      (rule.referenced_security_group_id != null ? 1 : 0) == 1
    ])
    error_message = "Each egress rule must specify exactly one traffic destination: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, or referenced_security_group_id."
  }

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      rule.from_port >= -1 && rule.from_port <= 65535 &&
      rule.to_port >= -1 && rule.to_port <= 65535 &&
      rule.from_port <= rule.to_port
    ])
    error_message = "Each egress rule must have from_port and to_port between -1 and 65535, with from_port <= to_port."
  }
}

variable "tags" {
  description = "Map of tags to apply to the security group."
  type        = map(string)
  default     = {}
}
