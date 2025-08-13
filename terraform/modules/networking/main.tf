# modules/networking/main.tf

# Data sources
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # NAT Gateway configuration based on environment
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_vpn_gateway   = var.enable_vpn_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention_days

  # Kubernetes-specific tags for subnets
  public_subnet_tags = merge(
    var.public_subnet_tags,
    {
      "kubernetes.io/role/elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  private_subnet_tags = merge(
    var.private_subnet_tags,
    {
      "kubernetes.io/role/internal-elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# Additional Security Groups
resource "aws_security_group" "additional_sg" {
  count = length(var.additional_security_groups)

  name_prefix = "${var.cluster_name}-${var.additional_security_groups[count.index].name}"
  vpc_id      = module.vpc.vpc_id
  description = var.additional_security_groups[count.index].description

  dynamic "ingress" {
    for_each = var.additional_security_groups[count.index].ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.additional_security_groups[count.index].egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-${var.additional_security_groups[count.index].name}"
    }
  )
}

# VPC Endpoints for private clusters (optional)
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-ec2-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-ecr-api-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-ecr-dkr-endpoint"
    }
  )
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoint" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name_prefix = "${var.cluster_name}-vpc-endpoint"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-vpc-endpoint-sg"
    }
  )
}

# Local values
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)
}

data "aws_region" "current" {}