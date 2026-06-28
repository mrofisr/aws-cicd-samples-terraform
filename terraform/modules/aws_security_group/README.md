# AWS Security Group Module

This module creates a single AWS security group with fully configurable ingress and egress rules defined as typed objects. Each rule is expressed as a named map entry, which keeps plans deterministic and avoids rule-ordering churn.

## Features

- Single security group with a user-supplied name and description
- Ingress rules defined as `map(object)` for stable, readable plans
- Egress rules defined as `map(object)` for stable, readable plans
- Support for four source/destination types per rule: CIDR blocks, IPv6 CIDR blocks, prefix lists, and security group references
- Input validation enforcing exactly one traffic source or destination per rule
- Port range validation on every rule

## Usage

```hcl
module "app_sg" {
  source = "./terraform/modules/aws_security_group"

  vpc_id              = module.vpc.vpc_id
  security_group_name = "app-service"
  description         = "Security group for the ECS application tasks"

  ingress_rules = {
    allow_alb = {
      description                  = "Traffic from ALB"
      from_port                    = 8080
      to_port                      = 8080
      protocol                     = "tcp"
      referenced_security_group_id = module.loadbalancer.alb_security_group_id
    }
  }

  egress_rules = {
    allow_all_outbound = {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | ID of the VPC where the security group is created | `string` | n/a | yes |
| security_group_name | Name of the security group | `string` | n/a | yes |
| description | Description applied to the security group resource | `string` | `"Managed by Terraform"` | no |
| ingress_rules | Map of ingress rules. Each rule must specify exactly one source: `cidr_blocks`, `ipv6_cidr_blocks`, `prefix_list_ids`, or `referenced_security_group_id` | `map(object({...}))` | `{}` | no |
| egress_rules | Map of egress rules. Each rule must specify exactly one destination: `cidr_blocks`, `ipv6_cidr_blocks`, `prefix_list_ids`, or `referenced_security_group_id` | `map(object({...}))` | `{}` | no |
| tags | Map of tags applied to the security group | `map(string)` | `{}` | no |

### Rule object schema

Both `ingress_rules` and `egress_rules` accept a `map` of objects with the following fields:

| Field | Description | Type | Default | Required |
|-------|-------------|------|---------|----------|
| description | Human-readable description for the rule | `string` | n/a | yes |
| from_port | Start of the port range (`-1` for all traffic) | `number` | n/a | yes |
| to_port | End of the port range (`-1` for all traffic) | `number` | n/a | yes |
| protocol | IP protocol (`tcp`, `udp`, `icmp`, `-1` for all) | `string` | `"tcp"` | no |
| cidr_blocks | List of IPv4 CIDR blocks (mutually exclusive with other source fields) | `list(string)` | `null` | no |
| ipv6_cidr_blocks | List of IPv6 CIDR blocks | `list(string)` | `null` | no |
| prefix_list_ids | List of prefix list IDs | `list(string)` | `null` | no |
| referenced_security_group_id | ID of a source/destination security group | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | The ID of the security group |
| security_group_arn | The ARN of the security group |
| owner_id | The AWS account ID that owns the security group |
| vpc_id | The VPC ID associated with the security group |

## Notes

- Each rule must specify exactly one traffic source or destination. The module validates this constraint and will error on `plan` if multiple source fields are set on the same rule.
- Use stable, descriptive map keys (e.g. `"allow_alb"`, `"allow_https"`) so that adding or removing a rule doesn't cause unrelated rules to be destroyed and recreated.
- The module creates inline `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources rather than inline rules on the security group, which avoids the well-known Terraform "default egress rule" conflict.
