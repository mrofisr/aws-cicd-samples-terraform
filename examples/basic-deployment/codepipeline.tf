module "codepipeline" {
  source = "../../terraform/modules/aws_codepipeline"

  pipeline_name = local.name_prefix

  codestar_connection_arn = var.codestar_connection_arn
  repo_owner              = var.repo_owner
  repo_name               = var.repo_name
  repo_branch             = var.repo_branch

  codebuild_project_name = module.codebuild.project_name

  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name

  s3_force_destroy = true

  tags = local.common_tags
}
