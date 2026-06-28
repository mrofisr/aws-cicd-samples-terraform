# AWS ECS Module

This module creates an ECS cluster, Fargate or EC2 task definition with CloudWatch logging, an ECS service with load balancer integration, and the required IAM roles for task execution and runtime.

## Features

- ECS cluster with Container Insights support
- Task definition supporting FARGATE or EC2 launch types
- Configurable CPU, memory, and container port
- CloudWatch Logs integration with configurable retention
- ECS service with health check grace period and load balancer registration
- Auto-created IAM execution role (ECR pull, CloudWatch Logs, Secrets Manager)
- Auto-created IAM task role for application runtime permissions
- Environment variable injection
- Public IP assignment for public subnet deployments

## Usage

```hcl
module "ecs" {
  source = "./terraform/modules/aws_ecs"

  cluster_name    = "my-app-cluster"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  security_group_ids = [module.app_sg.security_group_id]

  launch_type      = "FARGATE"
  container_name   = "web-app"
  container_image  = "${module.ecr.repository_url}:latest"
  container_port   = 8080

  cpu    = "256"
  memory = "512"

  desired_count     = 2
  target_group_arn  = module.loadbalancer.target_group_arn
  assign_public_ip  = false

  environment_variables = {
    ENVIRONMENT = "production"
    PORT        = "8080"
  }

  log_retention_in_days = 30

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the ECS cluster (also used as prefix for service, task family, IAM roles, and log group) | `string` | n/a | yes |
| vpc_id | VPC ID where the ECS service runs (used for tagging and scoping) | `string` | n/a | yes |
| subnet_ids | Subnet IDs where ECS tasks are placed. For FARGATE, use private subnets with NAT gateway or VPC endpoints for ECR/CloudWatch access | `list(string)` | n/a | yes |
| security_group_ids | Security group IDs attached to task ENIs (FARGATE awsvpc mode). Should allow ALB ingress on container_port and ECR/CloudWatch egress | `list(string)` | `[]` | no |
| launch_type | Launch type: `FARGATE` (serverless) or `EC2` (container instances) | `string` | `"FARGATE"` | no |
| container_name | Name of the primary container in the task definition. Referenced by the load balancer target group | `string` | `"web-app"` | no |
| container_image | Container image URI (e.g. `<account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`). Updated by CodePipeline deploy stage | `string` | n/a | yes |
| container_port | Port the container listens on (matches the Go app's PORT). Registered with the load balancer | `number` | `8080` | no |
| cpu | CPU units for the task (e.g. `256` = 0.25 vCPU). For FARGATE, must be a valid task-level value | `string` | `"256"` | no |
| memory | Memory in MiB for the task. For FARGATE, must be a valid combination with cpu (e.g. cpu 256 supports memory 512, 1024, 2048) | `string` | `"512"` | no |
| desired_count | Number of task instances the service maintains | `number` | `1` | no |
| target_group_arn | ARN of the load balancer target group. When null, the service runs without load balancer registration | `string` | `null` | no |
| assign_public_ip | Whether to assign public IPs to task ENIs (awsvpc mode). Set to true only for public subnet deployments without NAT | `bool` | `false` | no |
| environment_variables | Map of plaintext environment variables injected into the container. Use Secrets Manager for sensitive values | `map(string)` | `{}` | no |
| log_retention_in_days | CloudWatch Logs retention period (days) | `number` | `30` | no |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the ECS cluster |
| cluster_arn | The ARN of the ECS cluster |
| cluster_name | The name of the ECS cluster |
| service_id | The ID (ARN) of the ECS service |
| service_name | The name of the ECS service |
| task_definition_arn | The full ARN of the task definition, including revision. Used by CodePipeline deploy stage |
| task_definition_family | The family name of the task definition |
| task_exec_role_arn | The ARN of the task execution role (pulls images, writes logs, reads secrets) |
| task_exec_role_name | The name of the task execution role. Attach additional policies here for execution-time permissions |
| task_role_arn | The ARN of the task role assumed by the running application container |

## Notes

- For FARGATE launch type, tasks must run in subnets with internet access (via NAT gateway or VPC endpoints) to pull images from ECR and write logs to CloudWatch.
- The task execution role is granted permissions to pull from ECR, write CloudWatch Logs, and read Secrets Manager secrets in the same region.
- The task role is a minimal IAM role for the running container. Attach additional policies to `task_role_arn` output for AWS SDK calls.
- `desired_count = 0` is valid and stops all tasks while keeping the service registered.
- Setting `assign_public_ip = true` is only necessary when tasks run in public subnets without a NAT gateway. This is not recommended for production.
- The module uses `awslogs` log driver to send container stdout/stderr to CloudWatch Logs.
