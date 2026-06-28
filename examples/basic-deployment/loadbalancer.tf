module "alb" {
  source = "../../terraform/modules/aws_loadbalancer"

  alb_name = local.name_prefix
  vpc_id   = module.vpc.vpc_id

  public_subnet_ids = module.vpc.public_subnet_ids
  internal          = false

  target_type    = "ip"
  container_port = var.container_port

  health_check_path = var.health_check_path

  ssl_certificate_arn = var.ssl_certificate_arn

  ingress_cidr_blocks = ["0.0.0.0/0"]

  deletion_protection = false

  tags = local.common_tags
}
