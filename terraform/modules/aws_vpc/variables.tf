variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g. \"10.0.0.0/16\")."
  }
}

variable "public_subnet_cidrs" {
  description = "List of IPv4 CIDR blocks for the public subnets. Each entry is placed in a distinct Availability Zone (round-robin)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "public_subnet_cidrs must contain at least 2 CIDR blocks for multi-AZ high availability."
  }

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in public_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "List of IPv4 CIDR blocks for the private subnets. Each entry is placed in a distinct Availability Zone (round-robin)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "private_subnet_cidrs must contain at least 2 CIDR blocks for multi-AZ high availability."
  }

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in private_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateway(s) so private subnets can reach the internet for egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "When true, provision a single shared NAT Gateway instead of one per Availability Zone. Only takes effect when enable_nat_gateway is true."
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
