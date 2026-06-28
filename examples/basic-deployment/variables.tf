variable "aws_region" {
  description = "AWS region to deploy all resources into."
  type        = string
  default     = "ap-southeast-3"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier (e.g. \"ap-southeast-3\")."
  }
}

variable "app_name" {
  description = "Short application name used as the base for resource names and tags."
  type        = string
  default     = "cicd-demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 3-32 chars, lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod). Used in resource names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "container_image" {
  description = "Initial container image URI deployed to ECS before the pipeline pushes its first build. Defaults to a public placeholder so the stack stands up cleanly; CodePipeline replaces it on each deploy."
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:latest"

  validation {
    condition     = length(trimspace(var.container_image)) > 0
    error_message = "container_image must not be empty."
  }
}

variable "container_port" {
  description = "Port the application container listens on. Matches the Go app's default PORT (8080)."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP path the ALB target group health check requests against the application."
  type        = string
  default     = "/health"
}

variable "ssl_certificate_arn" {
  description = "ARN of an ACM certificate for the ALB HTTPS listener. When set, an HTTPS (443) listener is created and HTTP is redirected to HTTPS. Leave null for HTTP-only."
  type        = string
  default     = null
}

variable "desired_count" {
  description = "Number of ECS task replicas the service maintains."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be zero or greater."
  }
}

variable "task_cpu" {
  description = "Fargate task-level CPU units, as a string (e.g. \"256\" = 0.25 vCPU)."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate task-level memory in MiB, as a string. Must be a valid combination with task_cpu."
  type        = string
  default     = "512"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g. \"10.0.0.0/16\")."
  }
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks for the public subnets (one per AZ). The ALB lives here. At least two are required for multi-AZ."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

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
  description = "IPv4 CIDR blocks for the private subnets (one per AZ). ECS tasks and in-VPC CodeBuild run here. At least two are required for multi-AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "private_subnet_cidrs must contain at least 2 CIDR blocks for multi-AZ high availability."
  }

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in private_subnet_cidrs must be a valid IPv4 CIDR block."
  }
}

variable "single_nat_gateway" {
  description = "When true, provision a single shared NAT Gateway instead of one per AZ. Cheaper for demos; less resilient for production."
  type        = bool
  default     = true
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar (CodeConnections) connection used by the pipeline Source stage to access GitHub. The connection must already exist and be in an Available state."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:code(star-connections|connections):", var.codestar_connection_arn))
    error_message = "codestar_connection_arn must be a valid CodeStar/CodeConnections connection ARN."
  }
}

variable "repo_owner" {
  description = "GitHub repository owner (user or organization)."
  type        = string

  validation {
    condition     = length(trimspace(var.repo_owner)) > 0
    error_message = "repo_owner must not be empty."
  }
}

variable "repo_name" {
  description = "GitHub repository name tracked by the pipeline."
  type        = string

  validation {
    condition     = length(trimspace(var.repo_name)) > 0
    error_message = "repo_name must not be empty."
  }
}

variable "repo_branch" {
  description = "Branch the pipeline Source stage tracks for new commits."
  type        = string
  default     = "main"

  validation {
    condition     = length(trimspace(var.repo_branch)) > 0
    error_message = "repo_branch must not be empty."
  }
}

variable "owner" {
  description = "The owner/creator tag value for resources."
  type        = string
  default     = "devops"
}
variable "cpu_architecture" {
  description = "CPU architecture for the ECS Fargate task. X86_64 for standard amd64, ARM64 for Graviton (cheaper, better perf/cost)."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be one of: X86_64, ARM64."
  }
}
