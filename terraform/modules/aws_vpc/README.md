# AWS VPC Module

This module creates a complete VPC with public and private subnets across multiple Availability Zones, Internet Gateway, and optional NAT Gateways for private subnet internet access.

## Features

- VPC with configurable CIDR block
- Multi-AZ public subnets with Internet Gateway routing
- Multi-AZ private subnets with optional NAT Gateway routing
- Configurable NAT Gateway deployment (one per AZ or single shared)
- DNS hostnames and DNS support configuration
- Automatic subnet-to-AZ distribution

## Usage

```hcl
module "vpc" {
  source = "./terraform/modules/aws_vpc"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | The IPv4 CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | List of IPv4 CIDR blocks for public subnets (min 2 for multi-AZ HA) | `list(string)` | n/a | yes |
| private_subnet_cidrs | List of IPv4 CIDR blocks for private subnets (min 2 for multi-AZ HA) | `list(string)` | n/a | yes |
| enable_nat_gateway | Whether to provision NAT Gateway(s) for private subnet internet access | `bool` | `true` | no |
| single_nat_gateway | When true, use a single shared NAT Gateway instead of one per AZ (cost savings, reduced HA) | `bool` | `false` | no |
| enable_dns_hostnames | Whether to enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_dns_support | Whether to enable DNS support in the VPC | `bool` | `true` | no |
| tags | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The IPv4 CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs, ordered by their position in public_subnet_cidrs |
| private_subnet_ids | List of private subnet IDs, ordered by their position in private_subnet_cidrs |
| public_route_table_id | The ID of the shared public route table |
| private_route_table_ids | List of private route table IDs, ordered by their position in private_subnet_cidrs |
| nat_gateway_ids | List of NAT Gateway IDs (empty when enable_nat_gateway is false) |
| internet_gateway_id | The ID of the Internet Gateway |

## Notes

- Public subnets receive auto-assigned public IPs and route traffic through the Internet Gateway.
- Private subnets route traffic through NAT Gateways when `enable_nat_gateway` is true, enabling outbound internet access while remaining private.
- Setting `single_nat_gateway = true` reduces costs but creates a single point of failure. Use only for development environments.
- Each subnet is placed in a distinct Availability Zone using round-robin distribution.
- At least 2 subnets in each tier are required for high availability (ALB requirement).
