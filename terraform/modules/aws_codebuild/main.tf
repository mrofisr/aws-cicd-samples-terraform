terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  create_role = var.service_role_arn == ""

  service_role_arn = local.create_role ? aws_iam_role.codebuild[0].arn : var.service_role_arn

  enable_vpc = var.vpc_id != ""

  enable_s3 = var.s3_bucket_arn != ""

  log_group_name = "/aws/codebuild/${var.project_name}"

  tags = merge(
    var.tags,
    {
      Name = var.project_name
    }
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days

  tags = local.tags
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  count = local.create_role ? 1 : 0

  statement {
    sid     = "CodeBuildAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  count = local.create_role ? 1 : 0

  name               = "${var.project_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "codebuild_permissions" {
  count = local.create_role ? 1 : 0

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.this.arn,
      "${aws_cloudwatch_log_group.this.arn}:*",
    ]
  }

  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPullPush"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.region}:*:repository/*",
    ]
  }

  dynamic "statement" {
    for_each = local.enable_s3 ? [1] : []

    content {
      sid    = "S3ArtifactsCache"
      effect = "Allow"

      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
      ]

      resources = [
        "${var.s3_bucket_arn}/*",
      ]
    }
  }

  dynamic "statement" {
    for_each = local.enable_vpc ? [1] : []

    content {
      sid    = "VpcNetworkInterfaces"
      effect = "Allow"

      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeVpcs",
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.enable_vpc ? [1] : []

    content {
      sid    = "VpcCreateNetworkInterfacePermission"
      effect = "Allow"

      actions = ["ec2:CreateNetworkInterfacePermission"]

      resources = [
        "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "ec2:AuthorizedService"
        values   = ["codebuild.amazonaws.com"]
      }

      condition {
        test     = "StringEquals"
        variable = "ec2:Subnet"
        values = [
          for subnet_id in var.subnet_ids :
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:subnet/${subnet_id}"
        ]
      }
    }
  }
}

resource "aws_iam_role_policy" "codebuild" {
  count = local.create_role ? 1 : 0

  name   = "${var.project_name}-codebuild"
  role   = aws_iam_role.codebuild[0].id
  policy = data.aws_iam_policy_document.codebuild_permissions[0].json
}

resource "aws_codebuild_project" "this" {
  name          = var.project_name
  description   = var.description
  service_role  = local.service_role_arn
  build_timeout = var.build_timeout
  badge_enabled = false

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = var.build_type
    privileged_mode = var.privileged_mode

    dynamic "environment_variable" {
      for_each = var.environment_variables

      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = coalesce(environment_variable.value.type, "PLAINTEXT")
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_path != "" ? var.buildspec_path : null
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = local.enable_s3 ? "S3" : "LOCAL"
    location = local.enable_s3 ? replace(var.s3_bucket_arn, "arn:${data.aws_partition.current.partition}:s3:::", "") : null
    modes    = local.enable_s3 ? null : ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
      status     = "ENABLED"
    }
  }

  dynamic "vpc_config" {
    for_each = local.enable_vpc ? [1] : []

    content {
      vpc_id             = var.vpc_id
      subnets            = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = local.tags
}
