# AWS CodePipeline Module

This module creates a fully automated CI/CD pipeline with three stages: Source (GitHub via CodeConnections), Build (CodeBuild), and Deploy (ECS). It includes an S3 artifact bucket, IAM role with necessary permissions, and integration with existing CodeBuild and ECS resources.

## Features

- Three-stage pipeline: Source → Build → Deploy
- Source stage using AWS CodeConnections (CodeStar) for GitHub integration
- Build stage invoking an existing CodeBuild project
- Deploy stage updating an ECS service with the new task definition
- Auto-created S3 bucket for pipeline artifacts with encryption
- Auto-created IAM role with least-privilege permissions
- Support for custom S3 bucket or auto-generated bucket name
- Configurable branch tracking

## Usage

```hcl
module "codepipeline" {
  source = "./terraform/modules/aws_codepipeline"

  pipeline_name           = "my-app-pipeline"
  codestar_connection_arn = "arn:aws:codestar-connections:us-west-2:783764617931789012:connection/78376461793178-1234-1234-1234-783764617931789012"
  
  repo_owner  = "myorg"
  repo_name   = "my-app"
  repo_branch = "main"

  codebuild_project_name = module.codebuild.project_name
  ecs_cluster_name       = module.ecs.cluster_name
  ecs_service_name       = module.ecs.service_name

  s3_bucket_name  = ""
  s3_force_destroy = false

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| pipeline_name | Name of the CodePipeline (also used as prefix for IAM role and artifact bucket) | `string` | n/a | yes |
| codestar_connection_arn | ARN of the AWS CodeStar (CodeConnections) connection. The connection must be in Available state | `string` | n/a | yes |
| repo_owner | GitHub repository owner (user or organization) | `string` | n/a | yes |
| repo_name | GitHub repository name | `string` | n/a | yes |
| repo_branch | Branch the Source stage tracks for new commits | `string` | `"main"` | no |
| codebuild_project_name | Name of the existing CodeBuild project the Build stage invokes | `string` | n/a | yes |
| ecs_cluster_name | Name of the ECS cluster the Deploy stage updates | `string` | n/a | yes |
| ecs_service_name | Name of the ECS service the Deploy stage updates with the new task definition revision | `string` | n/a | yes |
| s3_bucket_name | Name of the S3 bucket for artifacts. When empty, generates a unique name from pipeline name and account ID | `string` | `""` | no |
| s3_force_destroy | Whether to allow Terraform to delete the artifact bucket even when it contains objects. Use `true` only for non-production pipelines | `bool` | `false` | no |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| pipeline_id | The ID of the CodePipeline |
| pipeline_name | The name of the CodePipeline |
| pipeline_arn | The ARN of the CodePipeline |
| role_arn | The ARN of the IAM role assumed by the pipeline |
| role_id | The ID (name) of the IAM role assumed by the pipeline |
| artifact_bucket_id | The ID (name) of the S3 bucket used as the artifact store |
| artifact_bucket_arn | The ARN of the S3 bucket used as the artifact store |

## Notes

- Before using this module, create an AWS CodeStar connection to GitHub via the AWS Console or CLI. The connection must be in the "Available" state. The ARN is required for the `codestar_connection_arn` input.
- The Source stage outputs a `SourceArtifact` containing the repository contents. The Build stage consumes it and produces a `BuildArtifact` containing `imagedefinitions.json`. The Deploy stage uses `imagedefinitions.json` to update the ECS service.
- The CodeBuild project's buildspec must produce an `imagedefinitions.json` file in the root of the build output. This file tells ECS which container image to deploy.
- The auto-created IAM role is granted permissions to:
  - Use the CodeStar connection (source action)
  - Read/write the artifact S3 bucket
  - Start builds in the specified CodeBuild project
  - Update the specified ECS service and pass the task execution/task roles
- When `s3_force_destroy = true`, Terraform can delete the bucket even if it contains objects. This is convenient for development but dangerous for production.
- The pipeline triggers automatically when new commits are pushed to the tracked branch.
