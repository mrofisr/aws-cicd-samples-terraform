terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : lower("${var.pipeline_name}-artifacts-${local.region}-${local.account_id}")

  full_repository_id = "${var.repo_owner}/${var.repo_name}"

  codebuild_project_arn   = "arn:aws:codebuild:${local.region}:${local.account_id}:project/${var.codebuild_project_name}"
  ecs_service_arn         = "arn:aws:ecs:${local.region}:${local.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  ecs_task_definition_arn = "arn:aws:ecs:${local.region}:${local.account_id}:task-definition/${var.ecs_cluster_name}-*"

  tags = merge(
    var.tags,
    {
      Name = var.pipeline_name
    }
  )
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.s3_force_destroy

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "CodePipelineAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.pipeline_name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "ArtifactStoreAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    sid    = "CodeBuildAccess"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = [local.codebuild_project_arn]
  }

  statement {
    sid    = "EcsServiceDeploy"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
      "ecs:UpdateService",
      "ecs:DescribeClusters",
      "ecs:DescribeCapacityProviders",
      "ecs:ListTaskDefinitions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "PassEcsTaskRoles"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = ["*"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
    }
  }

  statement {
    sid    = "PassEcsTaskRolesSpecific"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/*-ecs-execution",
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/*-ecs-task",
    ]
  }

  statement {
    sid    = "UseCodeStarConnection"
    effect = "Allow"

    actions = ["codestar-connections:UseConnection"]

    resources = [var.codestar_connection_arn]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.pipeline_name}-codepipeline"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_codepipeline" "this" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.this.arn

  artifact_store {
    location = aws_s3_bucket.this.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = local.full_repository_id
        BranchName           = var.repo_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["BuildOutput"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  tags = local.tags
}
