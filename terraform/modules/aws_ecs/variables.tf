variable "cluster_name" {
  description = "Name of the ECS cluster. Also used as the prefix for the service, task definition family, IAM roles, and CloudWatch log group created by this module."
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "cluster_name must not be empty."
  }
}

variable "vpc_id" {
  description = "ID of the VPC in which the ECS service runs. Used for tagging and to scope networking resources for the workload."
  type        = string

  validation {
    condition     = length(var.vpc_id) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs the ECS service places tasks into. For FARGATE (awsvpc networking) these are attached directly to each task's elastic network interface; use private subnets with a NAT gateway (or VPC endpoints) so tasks can pull images from ECR."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet ID."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs attached to the task ENIs when awsvpc networking is used (FARGATE). These should allow inbound traffic from the load balancer on container_port and outbound traffic for image pulls and logging."
  type        = list(string)
  default     = []
}

variable "launch_type" {
  description = "Launch type for the ECS service. FARGATE runs serverless tasks with awsvpc networking; EC2 schedules tasks onto container instances registered to the cluster."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "launch_type must be either FARGATE or EC2."
  }
}

variable "container_name" {
  description = "Name of the primary container in the task definition. This name is referenced by the load balancer target group when wiring up the service."
  type        = string
  default     = "web-app"
}

variable "container_image" {
  description = "Container image URI to deploy (e.g. <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>). Typically supplied from the ECR module output and updated by the CodePipeline deploy stage."
  type        = string

  validation {
    condition     = length(var.container_image) > 0
    error_message = "container_image must not be empty."
  }
}

variable "container_port" {
  description = "Port the container listens on. Matches the Go application's PORT (8080) and is registered with the load balancer target group."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "cpu" {
  description = "CPU units for the task definition, as a string. For FARGATE this must be a valid task-level value (e.g. 256, 512, 1024). 256 equals 0.25 vCPU."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory (in MiB) for the task definition, as a string. For FARGATE this must be a valid combination with cpu (e.g. cpu 256 supports memory 512, 1024, 2048)."
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of task instances the ECS service maintains. The service scheduler launches replacements to keep this many tasks running."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be zero or greater."
  }
}

variable "target_group_arn" {
  description = "ARN of an ALB/NLB target group to register tasks with for load balancer routing. When null, no load balancer is attached and the service runs without ingress registration."
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to task ENIs when using awsvpc networking (FARGATE). Set to true only when tasks run in public subnets without a NAT gateway, since image pulls and logging require outbound internet access."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Map of environment variables injected into the primary container as plaintext name/value pairs. Placeholder for application configuration; use secrets for sensitive values instead."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "Retention period, in days, for the CloudWatch Logs group that captures container stdout/stderr via the awslogs driver."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources created by this module. Merged with module-managed tags such as the Name tag."
  type        = map(string)
  default     = {}
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of desired_count) for the number of running tasks during a deployment. Controls cost and resource usage during rolling updates."
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100
    error_message = "deployment_maximum_percent must be at least 100."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of desired_count) for the number of healthy tasks during a deployment. Controls availability during rolling updates."
  type        = number
  default     = 0

  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "deployment_minimum_healthy_percent must be between 0 and 100."
  }
}

variable "deployment_circuit_breaker_enabled" {
  description = "Whether to enable deployment circuit breaker that automatically stops failed deployments and optionally rolls back to the previous version."
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "Whether the deployment circuit breaker should automatically roll back failed deployments to the previous task definition."
  type        = bool
  default     = true
}

variable "cpu_architecture" {
  description = "CPU architecture for the ECS task. Use X86_64 for standard amd64 workloads or ARM64 for Graviton-based tasks. Both are supported by Fargate."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be one of: X86_64, ARM64."
  }
}
