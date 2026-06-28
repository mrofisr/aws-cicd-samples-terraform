variable "vpc_id" {
  description = "ID of the VPC where the load balancer and target group are created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must be a non-empty string."
  }
}

variable "public_subnet_ids" {
  description = "List of subnet IDs the Application Load Balancer is attached to. Use public subnets for internet-facing load balancers."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "public_subnet_ids must contain at least two subnet IDs in distinct Availability Zones."
  }
}

variable "alb_name" {
  description = "Name of the Application Load Balancer. Also used as the base name for the target group and security group."
  type        = string

  validation {
    condition     = length(trimspace(var.alb_name)) > 0
    error_message = "alb_name must be a non-empty string."
  }
}

variable "internal" {
  description = "Whether the load balancer is internal (true) or internet-facing (false)."
  type        = bool
  default     = false
}

variable "target_type" {
  description = "Target type for the target group. Use \"ip\" for Fargate (default) and \"instance\" for EC2 launch type."
  type        = string
  default     = "ip"

  validation {
    condition     = contains(["ip", "instance", "lambda", "alb"], var.target_type)
    error_message = "target_type must be one of: ip, instance, lambda, alb."
  }
}

variable "container_port" {
  description = "Port the target group forwards traffic to (the container/application port)."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "Destination path for the target group health check."
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Port used by the target group health check. Use \"traffic-port\" to reuse the target port."
  type        = string
  default     = "traffic-port"
}

variable "health_check_interval" {
  description = "Approximate amount of time, in seconds, between health checks of an individual target."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Amount of time, in seconds, during which no response means a failed health check."
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive successful health checks before a target is considered healthy."
  type        = number
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks before a target is considered unhealthy."
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "HTTP response codes that indicate a healthy target (e.g. \"200\" or \"200-399\")."
  type        = string
  default     = "200"
}

variable "ssl_certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener. When set, an HTTPS listener on port 443 is created and the HTTP listener redirects to HTTPS."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "Name of the SSL policy applied to the HTTPS listener. Only used when ssl_certificate_arn is set."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the load balancer listeners (HTTP/HTTPS)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the load balancer."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "create_acm_certificate" {
  description = "When true, automatically creates and validates an ACM certificate for domain_name. Requires route53_zone_id and domain_name to be set. Takes precedence over ssl_certificate_arn when both are provided."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Primary domain name for the ACM certificate (e.g. \"app.example.com\"). Required when create_acm_certificate is true."
  type        = string
  default     = null
}

variable "subject_alternative_names" {
  description = "Additional domain names (SANs) to include in the ACM certificate (e.g. [\"www.example.com\"]). Only used when create_acm_certificate is true."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID used for DNS validation of the ACM certificate. Required when create_acm_certificate is true."
  type        = string
  default     = null

  validation {
    condition     = !var.create_acm_certificate || (var.route53_zone_id != null && length(trimspace(var.route53_zone_id)) > 0)
    error_message = "route53_zone_id is required when create_acm_certificate is true."
  }
}
