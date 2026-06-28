variable "project_name" {
  description = "Name of the CodeBuild project. Also used as a prefix for the auto-created IAM role and CloudWatch log group."
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must not be empty."
  }
}

variable "description" {
  description = "Description applied to the CodeBuild project."
  type        = string
  default     = "CodeBuild project managed by Terraform"
}

variable "build_image" {
  description = "Docker image used for the build environment (e.g. an AWS-managed CodeBuild image or a custom ECR image)."
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
}

variable "build_compute_type" {
  description = "CodeBuild compute type that determines the CPU and memory available to the build environment."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE",
    ], var.build_compute_type)
    error_message = "build_compute_type must be one of: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE, BUILD_GENERAL1_2XLARGE."
  }
}

variable "build_type" {
  description = "Type of build environment container."
  type        = string
  default     = "LINUX_CONTAINER"

  validation {
    condition     = contains(["LINUX_CONTAINER", "WINDOWS_CONTAINER"], var.build_type)
    error_message = "build_type must be either LINUX_CONTAINER or WINDOWS_CONTAINER."
  }
}

variable "privileged_mode" {
  description = "Whether to run the build in privileged mode. Required for building Docker images inside the build container."
  type        = bool
  default     = true
}

variable "build_timeout" {
  description = "Number of minutes, from 5 to 480, before an in-progress build times out."
  type        = number
  default     = 60

  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 480
    error_message = "build_timeout must be between 5 and 480 minutes."
  }
}

variable "service_role_arn" {
  description = "ARN of an existing IAM service role for CodeBuild to assume. When empty, the module creates a least-privilege role."
  type        = string
  default     = ""
}

variable "buildspec_path" {
  description = "Path to the buildspec file within the source (e.g. \"buildspec.yml\"). When empty, CodeBuild uses buildspec.yml at the source root."
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Environment variables exposed to the build. type is one of PLAINTEXT, PARAMETER_STORE, or SECRETS_MANAGER."
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "PLAINTEXT")
  }))
  default = []

  validation {
    condition = alltrue([
      for env in var.environment_variables :
      contains(["PLAINTEXT", "PARAMETER_STORE", "SECRETS_MANAGER"], coalesce(env.type, "PLAINTEXT"))
    ])
    error_message = "environment_variables[*].type must be one of: PLAINTEXT, PARAMETER_STORE, SECRETS_MANAGER."
  }
}

variable "vpc_id" {
  description = "VPC ID to run builds inside. When empty, builds run outside any VPC. Requires subnet_ids and security_group_ids when set."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs the build network interfaces are placed in. Only used when vpc_id is set."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs attached to the build network interfaces. Only used when vpc_id is set."
  type        = list(string)
  default     = []
}

variable "s3_bucket_arn" {
  description = "ARN of an S3 bucket used for build caching and as an artifact store. When empty, a LOCAL cache is used instead."
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "Number of days to retain CodeBuild logs in CloudWatch Logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to all resources created by the module."
  type        = map(string)
  default     = {}
}
