# environments/stage/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Local values specific to stage environment
locals {
  environment = "stage"
  cluster_name = "${var.project_name}-${local.environment}"

  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
    Purpose     = "Staging"
  }
}

# Data sources
data "aws_caller_identity" "current" {}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  cluster_name = local.cluster_name
  vpc_cidr     = var.vpc_cidr

  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  # Staging networking configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = false  # Multi-AZ for staging
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  # Flow logs - enabled for staging
  enable_flow_logs         = true
  flow_log_retention_days = 14

  # VPC endpoints - optional for staging
  enable_vpc_endpoints = false
  number_of_azs       = var.number_of_azs

  additional_security_groups = var.additional_security_groups

  common_tags = local.common_tags
  vpc_tags = {
    Environment = local.environment
    Type        = "Staging"
  }

  public_subnet_tags = {
    Type = "Public"
    Environment = local.environment
  }

  private_subnet_tags = {
    Type = "Private"
    Environment = local.environment
  }
}

# EKS Cluster Module
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name       = local.cluster_name
  environment        = local.environment
  kubernetes_version = var.kubernetes_version

  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnets

  # Staging cluster configuration
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_enabled_log_types       = ["api", "audit", "authenticator"]

  # Staging node groups
  node_groups = var.node_groups

  eks_admin_users = var.eks_admin_users
  aws_auth_roles  = var.aws_auth_roles

  addon_versions = var.addon_versions

  common_tags = local.common_tags
  cluster_tags = {
    Environment = local.environment
    Purpose     = "Staging"
  }

  depends_on = [module.networking]
}

# Configure Kubernetes and Helm providers
provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_id]
    }
  }
}

# EKS Addons Module
module "eks_addons" {
  source = "../../modules/addons"

  cluster_name     = module.eks_cluster.cluster_id
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  environment      = local.environment

  # Staging addon configuration
  enable_cluster_autoscaler = true
  enable_external_dns      = var.enable_external_dns
  enable_metrics_server    = true
  enable_aws_load_balancer_controller = true
  enable_cert_manager      = false  # Optional for staging
  enable_ingress_nginx     = false

  domain_name = var.domain_name
  aws_region  = var.aws_region

  common_tags = local.common_tags

  depends_on = [module.eks_cluster]
}

# ArgoCD Module
module "argocd" {
  source = "../../modules/argocd"

  cluster_name          = module.eks_cluster.cluster_id
  cluster_endpoint      = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = module.eks_cluster.cluster_certificate_authority_data
  environment           = local.environment

  # ArgoCD configuration for staging
  argocd_version = var.argocd_version

  # Bootstrap configuration
  bootstrap_argocd    = var.bootstrap_argocd
  gitops_repo_url     = var.gitops_repo_url
  gitops_repo_branch  = var.gitops_repo_branch
  gitops_repo_path    = var.gitops_repo_path
  auto_sync_prune     = var.auto_sync_prune
  auto_sync_self_heal = var.auto_sync_self_heal
  use_custom_project  = var.use_custom_project

  # Staging-specific ArgoCD settings
  server_replicas    = 2
  controller_replicas = 1
  repo_server_replicas = 2

  # Resource limits for staging
  server_resources = {
    requests = {
      cpu    = "200m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }

  controller_resources = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2"
      memory = "4Gi"
    }
  }

  repo_server_resources = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }

  common_tags = local.common_tags

  depends_on = [module.eks_addons]
}

