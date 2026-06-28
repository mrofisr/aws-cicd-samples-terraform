terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

locals {
  lifecycle_tag_status = var.lifecycle_policy == null ? null : lower(coalesce(var.lifecycle_policy.tag_status, "any"))
  lifecycle_rules = var.lifecycle_policy == null ? [] : concat(
    try(var.lifecycle_policy.max_image_count, null) == null ? [] : [{
      rulePriority = 1
      description  = "Expire images beyond ${var.lifecycle_policy.max_image_count}"
      selection = merge(
        {
          countType   = "imageCountMoreThan"
          countNumber = tonumber(var.lifecycle_policy.max_image_count)
          tagStatus   = local.lifecycle_tag_status
        },
        local.lifecycle_tag_status == "tagged" ? {
          tagPrefixList = coalesce(var.lifecycle_policy.tag_prefix_list, [])
        } : {}
      )
      action = {
        type = "expire"
      }
    }],
    try(var.lifecycle_policy.max_age_days, null) == null ? [] : [{
      rulePriority = 2
      description  = "Expire images older than ${var.lifecycle_policy.max_age_days} days"
      selection = merge(
        {
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = tonumber(var.lifecycle_policy.max_age_days)
          tagStatus   = local.lifecycle_tag_status
        },
        local.lifecycle_tag_status == "tagged" ? {
          tagPrefixList = coalesce(var.lifecycle_policy.tag_prefix_list, [])
        } : {}
      )
      action = {
        type = "expire"
      }
    }]
  )
}

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.image_scanning_configuration.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_configuration.encryption_type
    kms_key         = var.encryption_configuration.encryption_type == "KMS" ? var.encryption_configuration.kms_key : null
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = length(local.lifecycle_rules) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      for rule in local.lifecycle_rules : merge(rule, {
        selection = merge(rule.selection, {
          countNumber = parseint(tostring(rule.selection.countNumber), 10)
        })
      })
    ]
  })
}

data "aws_iam_policy_document" "cross_account" {
  count = var.enable_repository_policy && length(var.cross_account_principals) > 0 ? 1 : 0

  statement {
    sid    = "CrossAccountPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.cross_account_principals
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
  }
}

resource "aws_ecr_repository_policy" "this" {
  count = var.enable_repository_policy && length(var.cross_account_principals) > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.cross_account[0].json
}
