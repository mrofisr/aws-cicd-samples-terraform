# AWS Load Balancer Module

This module creates an Application Load Balancer with target group, HTTP/HTTPS listeners, and an associated security group. It supports internet-facing and internal configurations with optional SSL certificate integration.

## Features

- Application Load Balancer with configurable scheme (internet-facing or internal)
- Target group with fully configurable health checks
- HTTP listener (port 80) with optional redirect to HTTPS
- Optional HTTPS listener (port 443) with ACM certificate
- Auto-created security group allowing HTTP/HTTPS traffic from configurable CIDR blocks
- Support for `ip` and `instance` target types (IP for Fargate, instance for EC2)

## Usage

```hcl
module "loadbalancer" {
  source = "./terraform/modules/aws_loadbalancer"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_name          = "my-app-alb"

  internal       = false
  target_type    = "ip"
  container_port = 8080

  health_check_path     = "/health"
  health_check_interval = 30
  health_check_timeout  = 5
  healthy_threshold     = 3
  unhealthy_threshold   = 3
  health_check_matcher  = "200"

  ssl_certificate_arn = null
  ingress_cidr_blocks = ["0.0.0.0/0"]
  deletion_protection = false

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | ID of the VPC where the load balancer and target group are created | `string` | n/a | yes |
| public_subnet_ids | Subnet IDs the ALB is attached to. Use public subnets for internet-facing ALBs (min 2 in different AZs) | `list(string)` | n/a | yes |
| alb_name | Name of the ALB (also used as base name for target group and security group) | `string` | n/a | yes |
| internal | Whether the load balancer is internal (`true`) or internet-facing (`false`) | `bool` | `false` | no |
| target_type | Target type for the target group: `ip` (Fargate), `instance` (EC2), `lambda`, or `alb` | `string` | `"ip"` | no |
| container_port | Port the target group forwards traffic to | `number` | `8080` | no |
| health_check_path | Destination path for target group health checks | `string` | `"/health"` | no |
| health_check_port | Port used for health checks. Use `"traffic-port"` to reuse the target port | `string` | `"traffic-port"` | no |
| health_check_interval | Seconds between health checks of an individual target | `number` | `30` | no |
| health_check_timeout | Seconds during which no response means a failed health check | `number` | `5` | no |
| healthy_threshold | Consecutive successful health checks before a target is considered healthy | `number` | `3` | no |
| unhealthy_threshold | Consecutive failed health checks before a target is considered unhealthy | `number` | `3` | no |
| health_check_matcher | HTTP response codes indicating a healthy target (e.g. `"200"` or `"200-399"`) | `string` | `"200"` | no |
| ssl_certificate_arn | ARN of the ACM certificate for the HTTPS listener. When set, creates HTTPS listener and redirects HTTP to HTTPS | `string` | `null` | no |
| ssl_policy | SSL policy for the HTTPS listener. Only used when `ssl_certificate_arn` is set | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| ingress_cidr_blocks | CIDR blocks allowed to reach the load balancer on HTTP/HTTPS | `list(string)` | `["0.0.0.0/0"]` | no |
| deletion_protection | Whether deletion protection is enabled on the load balancer | `bool` | `false` | no |
| tags | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_id | ID of the Application Load Balancer |
| alb_arn | ARN of the Application Load Balancer |
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_zone_id | Canonical hosted zone ID of the ALB (for Route 53 alias records) |
| alb_security_group_id | ID of the security group attached to the load balancer |
| target_group_arn | ARN of the target group |
| target_group_name | Name of the target group |
| target_group_id | ID of the target group |
| http_listener_arn | ARN of the HTTP (port 80) listener |
| https_listener_arn | ARN of the HTTPS (port 443) listener, or null when SSL is not configured |

## Notes

- When `ssl_certificate_arn` is provided, the HTTP listener automatically redirects all traffic to HTTPS. Without it, HTTP traffic is forwarded directly to targets.
- Use `target_type = "ip"` for ECS Fargate tasks and `target_type = "instance"` for EC2 launch type.
- The health check path should return HTTP 200 when the application is healthy. The Go application exposes `/health` for this purpose.
- For production workloads, set `deletion_protection = true` to prevent accidental ALB deletion via Terraform or the console.
- At least 2 subnets in different Availability Zones are required by AWS for load balancer deployment.
- The auto-created security group allows inbound HTTP (80) and HTTPS (443) from `ingress_cidr_blocks` and all outbound traffic to targets.
