terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = data.aws_availability_zones.available.names

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs : cidr => {
      az       = local.azs[idx % length(local.azs)]
      az_index = idx
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs : cidr => {
      az       = local.azs[idx % length(local.azs)]
      az_index = idx
    }
  }

  nat_gateway_enabled = var.enable_nat_gateway

  nat_subnet_cidrs = local.nat_gateway_enabled ? (
    var.single_nat_gateway ? slice(var.public_subnet_cidrs, 0, 1) : var.public_subnet_cidrs
  ) : []

  nat_subnets = {
    for cidr in local.nat_subnet_cidrs : cidr => local.public_subnets[cidr]
  }

  private_subnet_nat_key = local.nat_gateway_enabled ? {
    for cidr, cfg in local.private_subnets :
    cidr => local.nat_subnet_cidrs[cfg.az_index % length(local.nat_subnet_cidrs)]
  } : {}
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = "vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.key
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.key
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "private-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  for_each = local.nat_subnets

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "nat-eip-${each.value.az}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "nat-${each.value.az}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "private-rt-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_route" "private_nat" {
  for_each = local.private_subnet_nat_key

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
