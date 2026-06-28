module "ecs" {
  source = "../../terraform/modules/aws_ecs"

  cluster_name = local.name_prefix
  vpc_id       = module.vpc.vpc_id

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.ecs_tasks_sg.security_group_id]

  launch_type      = "FARGATE"
  assign_public_ip = false

  container_name  = "${local.name_prefix}-app"
  container_image = var.container_image
  container_port  = var.container_port

  cpu           = var.task_cpu
  memory        = var.task_memory
  desired_count = var.desired_count

  cpu_architecture = var.cpu_architecture

  target_group_arn = module.alb.target_group_arn

  environment_variables = {
    PORT = tostring(var.container_port)
  }

  tags = local.common_tags

  depends_on = [module.alb]
}
