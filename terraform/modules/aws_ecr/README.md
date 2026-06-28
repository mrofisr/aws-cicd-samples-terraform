# AWS ECR Module

This module creates a private Amazon Elastic Container Registry repository with configurable image scanning, encryption, lifecycle policies, and optional cross-account pull access.

## Features

- Private ECR repository with configurable tag mutability
- Automatic vulnerability scanning on push
- AES-256 or customer-managed KMS encryption
- Optional lifecycle policy to cap image count or expire images by age
- Optional repository policy for cross-account pull access

## Usage

```hcl
module "ecr" {
  source = "./terraform/modules/aws_ecr"

  repository_name      = "my-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration = {
    scan_on_push = true
  }

  encryption_configuration = {
    encryption_type = "AES256"
    kms_key         = null
  }

  lifecycle_policy = {
    max_image_count = 20
    tag_status      = "any"
  }

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| image_tag_mutability | Tag mutability setting: `MUTABLE` or `IMMUTABLE` | `string` | `"MUTABLE"` | no |
| image_scanning_configuration | Scanning config. `scan_on_push = true` triggers a vulnerability scan on every push | `object({ scan_on_push = bool })` | `{ scan_on_push = true }` | no |
| encryption_configuration | Encryption config. `encryption_type` is `AES256` or `KMS`; `kms_key` is required only for customer-managed keys | `object({ encryption_type = string, kms_key = optional(string) })` | `{ encryption_type = "AES256" }` | no |
| lifecycle_policy | Optional lifecycle policy. Set `max_image_count` or `max_age_days` (or both). `tag_status` filters which images the rule applies to: `any`, `tagged`, or `untagged` | `object({...})` | `null` | no |
| enable_repository_policy | Whether to attach a repository policy granting cross-account pull access | `bool` | `false` | no |
| cross_account_principals | IAM principal ARNs granted pull access via the repository policy. Only used when `enable_repository_policy` is true | `list(string)` | `[]` | no |
| tags | Tags applied to the ECR repository | `map(string)` | `{}` | no |

### lifecycle_policy object schema

| Field | Description | Type | Default |
|-------|-------------|------|---------|
| max_image_count | Expire images when the total count exceeds this number | `number` | `null` |
| max_age_days | Expire images older than this many days | `number` | `null` |
| tag_status | Which images the rule applies to: `any`, `tagged`, `untagged` | `string` | `"any"` |
| tag_prefix_list | Required when `tag_status = "tagged"`. List of image tag prefixes to match | `list(string)` | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| repository_url | The URL of the ECR repository (used by CodeBuild to push and ECS to pull) |
| repository_arn | The ARN of the ECR repository |
| repository_name | The name of the ECR repository |
| registry_id | The registry ID (AWS account ID) where the repository was created |

## Notes

- Use `IMMUTABLE` tag mutability in production to prevent image tags from being overwritten, which makes deployments more predictable.
- `lifecycle_policy` must set at least one of `max_image_count` or `max_age_days`. The module validates this and will error on `plan` otherwise.
- When `tag_status = "tagged"`, `tag_prefix_list` must be non-empty.
- To use a customer-managed KMS key, set `encryption_type = "KMS"` and supply the key ARN in `kms_key`. The key policy must allow the ECR service to use it.
- `cross_account_principals` should contain IAM role or root ARNs, not user ARNs, for production workloads.
