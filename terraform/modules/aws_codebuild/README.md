# AWS CodeBuild Module

This module creates a CodeBuild project with customizable build environment, IAM role, CloudWatch logging, and optional VPC configuration. Designed for containerized application builds that produce Docker images.

## Features

- CodeBuild project with configurable compute type and build image
- Auto-created least-privilege IAM service role or bring-your-own role support
- CloudWatch Logs integration with configurable retention
- Support for privileged mode (required for Docker image builds)
- Environment variables with support for plaintext, Parameter Store, and Secrets Manager
- Optional VPC configuration for builds requiring private network access
- S3 bucket integration for build caching and artifacts
- Build badge URL for status display

## Usage

```hcl
module "codebuild" {
  source = "./terraform/modules/aws_codebuild"

  project_name       = "my-app-build"
  description        = "Build project for my containerized application"
  build_image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
  build_compute_type = "BUILD_GENERAL1_SMALL"
  build_type         = "LINUX_CONTAINER"
  privileged_mode    = true
  build_timeout      = 60

  buildspec_path = "buildspec.yml"

  environment_variables = [
    {
      name  = "AWS_DEFAULT_REGION"
      value = "us-west-2"
      type  = "PLAINTEXT"
    },
    {
      name  = "ECR_REPOSITORY_URI"
      value = module.ecr.repository_url
      type  = "PLAINTEXT"
    }
  ]

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.build_sg.security_group_id]

  s3_bucket_arn         = module.codepipeline.artifact_bucket_arn
  log_retention_in_days = 30

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the CodeBuild project (also used as prefix for IAM role and CloudWatch log group) | `string` | n/a | yes |
| description | Description applied to the CodeBuild project | `string` | `"CodeBuild project managed by Terraform"` | no |
| build_image | Docker image for the build environment (AWS-managed or custom ECR image) | `string` | `"aws/codebuild/amazonlinux2-x86_64-standard:3.0"` | no |
| build_compute_type | CodeBuild compute type: `BUILD_GENERAL1_SMALL`, `BUILD_GENERAL1_MEDIUM`, `BUILD_GENERAL1_LARGE`, `BUILD_GENERAL1_2XLARGE` | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| build_type | Type of build environment container: `LINUX_CONTAINER` or `WINDOWS_CONTAINER` | `string` | `"LINUX_CONTAINER"` | no |
| privileged_mode | Whether to run builds in privileged mode. Required for building Docker images | `bool` | `true` | no |
| build_timeout | Build timeout in minutes (5-480) | `number` | `60` | no |
| service_role_arn | ARN of existing IAM service role for CodeBuild. When empty, creates a least-privilege role | `string` | `""` | no |
| buildspec_path | Path to buildspec file within source (e.g. `"buildspec.yml"`). When empty, uses `buildspec.yml` at source root | `string` | `""` | no |
| environment_variables | Environment variables exposed to the build. `type` is `PLAINTEXT`, `PARAMETER_STORE`, or `SECRETS_MANAGER` | `list(object({...}))` | `[]` | no |
| vpc_id | VPC ID to run builds inside. When empty, builds run outside any VPC | `string` | `""` | no |
| subnet_ids | Subnet IDs for build network interfaces. Only used when `vpc_id` is set | `list(string)` | `[]` | no |
| security_group_ids | Security group IDs for build network interfaces. Only used when `vpc_id` is set | `list(string)` | `[]` | no |
| s3_bucket_arn | ARN of S3 bucket for build caching and artifacts. When empty, uses LOCAL cache | `string` | `""` | no |
| log_retention_in_days | CloudWatch Logs retention period in days | `number` | `30` | no |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

### environment_variables object schema

| Field | Description | Type | Default |
|-------|-------------|------|---------|
| name | Environment variable name | `string` | n/a |
| value | Value (or Parameter Store/Secrets Manager path) | `string` | n/a |
| type | Variable type: `PLAINTEXT`, `PARAMETER_STORE`, or `SECRETS_MANAGER` | `string` | `"PLAINTEXT"` |

## Outputs

| Name | Description |
|------|-------------|
| project_id | The ID (name) of the CodeBuild project |
| project_name | The name of the CodeBuild project |
| project_arn | The ARN of the CodeBuild project (referenced by CodePipeline build stages) |
| role_id | The name of the auto-created IAM role, or null when an external role ARN was supplied |
| role_arn | The ARN of the service role used by the project |
| log_group_name | The name of the CloudWatch log group receiving build logs |
| badge_url | The publicly accessible build badge URL for the project |

## Notes

- Set `privileged_mode = true` when building Docker images inside the build container. This grants the build container access to the Docker daemon.
- When using VPC configuration, ensure the subnets have outbound internet access (via NAT gateway) or VPC endpoints for ECR, S3, CloudWatch Logs, and Secrets Manager.
- The auto-created IAM role includes permissions for ECR push/pull, S3 artifact bucket access, CloudWatch Logs, and VPC ENI management when VPC is configured.
- Use `PARAMETER_STORE` and `SECRETS_MANAGER` environment variable types for sensitive build-time configuration instead of plaintext.
- The buildspec should output an `imagedefinitions.json` file, which the CodePipeline ECS deploy stage uses to update the service.
