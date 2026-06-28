module "ecr" {
  source = "../../terraform/modules/aws_ecr"

  repository_name      = local.name_prefix
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration = {
    scan_on_push = true
  }

  lifecycle_policy = {
    max_image_count = 10
    tag_status      = "any"
  }

  tags = local.common_tags
}