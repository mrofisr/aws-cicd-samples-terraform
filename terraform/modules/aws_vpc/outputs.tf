output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets, ordered by their position in public_subnet_cidrs."
  value       = [for cidr in var.public_subnet_cidrs : aws_subnet.public[cidr].id]
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets, ordered by their position in private_subnet_cidrs."
  value       = [for cidr in var.private_subnet_cidrs : aws_subnet.private[cidr].id]
}

output "public_route_table_id" {
  description = "The ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables, ordered by their position in private_subnet_cidrs."
  value       = [for cidr in var.private_subnet_cidrs : aws_route_table.private[cidr].id]
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways. Empty when enable_nat_gateway is false."
  value       = [for cidr in local.nat_subnet_cidrs : aws_nat_gateway.this[cidr].id]
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}
