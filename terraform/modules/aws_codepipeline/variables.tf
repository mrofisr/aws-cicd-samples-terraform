variable "pipeline_name" {
  description = "Name of the CodePipeline. Also used as the prefix for the IAM role and auto-generated artifact bucket created by this module."
  type        = string

  validation {
    condition     = length(var.pipeline_name) > 0
    error_message = "pipeline_name must not be empty."
  }
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar (CodeConnections) connection used by the Source stage to access the GitHub repository. The connection must already be created and in an Available state."
  type        = string

  validation {
    condition     = length(var.codestar_connection_arn) > 0
    error_message = "codestar_connection_arn must not be empty."
  }
}

variable "repo_owner" {
  description = "GitHub repository owner (user or organization). Combined with repo_name to form the FullRepositoryId consumed by the CodeStarSourceConnection action."
  type        = string

  validation {
    condition     = length(var.repo_owner) > 0
    error_message = "repo_owner must not be empty."
  }
}

variable "repo_name" {
  description = "GitHub repository name. Combined with repo_owner to form the FullRepositoryId consumed by the CodeStarSourceConnection action."
  type        = string

  validation {
    condition     = length(var.repo_name) > 0
    error_message = "repo_name must not be empty."
  }
}

variable "repo_branch" {
  description = "Branch the Source stage tracks for new commits."
  type        = string
  default     = "main"
}

variable "codebuild_project_name" {
  description = "Name of the existing CodeBuild project the Build stage invokes. The project's buildspec must produce the imagedefinitions.json artifact consumed by the ECS Deploy stage."
  type        = string

  validation {
    condition     = length(var.codebuild_project_name) > 0
    error_message = "codebuild_project_name must not be empty."
  }
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster the Deploy stage updates."
  type        = string

  validation {
    condition     = length(var.ecs_cluster_name) > 0
    error_message = "ecs_cluster_name must not be empty."
  }
}

variable "ecs_service_name" {
  description = "Name of the ECS service the Deploy stage updates with the new task definition revision."
  type        = string

  validation {
    condition     = length(var.ecs_service_name) > 0
    error_message = "ecs_service_name must not be empty."
  }
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket used as the CodePipeline artifact store. When empty, a unique bucket name is generated from the pipeline name and the current AWS account ID."
  type        = string
  default     = ""
}

variable "s3_force_destroy" {
  description = "Whether to allow Terraform to delete the artifact bucket even when it still contains objects. Set to true only for non-production or ephemeral pipelines."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources created by this module. Merged with module-managed tags such as the Name tag."
  type        = map(string)
  default     = {}
}
