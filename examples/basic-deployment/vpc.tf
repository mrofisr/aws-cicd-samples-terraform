module "vpc" {
  source = "../../terraform/modules/aws_vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  tags = local.common_tags
}

module "codebuild_sg" {
  source = "../../terraform/modules/aws_security_group"

  security_group_name = "${local.name_prefix}-codebuild-sg"
  description         = "Egress-only security group for CodeBuild network interfaces."
  vpc_id              = module.vpc.vpc_id

  egress_rules = {
    all_outbound = {
      description = "Allow all outbound traffic (ECR push, Docker Hub pulls, logging)."
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.common_tags
}

module "ecs_tasks_sg" {
  source = "../../terraform/modules/aws_security_group"

  security_group_name = "${local.name_prefix}-ecs-tasks-sg"
  description         = "Allow inbound traffic from the ALB to ECS tasks on the container port."
  vpc_id              = module.vpc.vpc_id

  ingress_rules = {
    from_alb = {
      description                  = "Container port from the Application Load Balancer."
      from_port                    = var.container_port
      to_port                      = var.container_port
      protocol                     = "tcp"
      referenced_security_group_id = module.alb.alb_security_group_id
    }
  }

  egress_rules = {
    all_outbound = {
      description = "Allow all outbound traffic (ECR pulls, CloudWatch logs, etc.)."
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.common_tags
}