module "codebuild" {
  source = "../../terraform/modules/aws_codebuild"

  buildspec_path = "buildspec.yml"

  project_name = local.name_prefix
  description  = "Builds and pushes the ${var.app_name} container image to ECR."

  privileged_mode = true
  build_timeout   = 30

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.codebuild_sg.security_group_id]

  s3_bucket_arn = "arn:aws:s3:::${local.name_prefix}-artifacts-${var.aws_region}-${data.aws_caller_identity.current.account_id}"

  environment_variables = [
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.region
    },
    {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    },
    {
      name  = "IMAGE_REPO_NAME"
      value = module.ecr.repository_name
    },
    {
      name  = "REPOSITORY_URI"
      value = module.ecr.repository_url
    },
    {
      name  = "CONTAINER_NAME"
      value = "${local.name_prefix}-app"
    },
  ]

  tags = local.common_tags
}
