# modules/eks-cluster/main.tf

# Data sources
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                          = var.vpc_id
  subnet_ids                      = var.private_subnet_ids
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # Enable cluster logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  # Node Groups - Dynamic based on environment
  eks_managed_node_groups = local.node_groups

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.eks_admin_users

  tags = merge(var.common_tags, var.cluster_tags)
}

# Local values for dynamic node group configuration
# Local values for dynamic node group configuration
locals {
  node_groups = {
    for ng_name, ng_config in var.node_groups : ng_name => {
      name           = "${ng_name}-nodes"
      instance_types = ng_config.instance_types

      min_size     = ng_config.min_size
      max_size     = ng_config.max_size
      desired_size = ng_config.desired_size

      # Convert taints map to list format expected by EKS module
      taints = ng_config.taints != null ? [
        for taint_name, taint_config in ng_config.taints : {
          key    = taint_config.key
          value  = taint_config.value
          effect = taint_config.effect
        }
      ] : []

      labels = merge(
        {
          role = ng_name
          "node.kubernetes.io/node-type" = ng_name
        },
          ng_config.labels != null ? ng_config.labels : {}
      )

      # Storage configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = ng_config.disk_size
            volume_type           = ng_config.disk_type
            iops                  = ng_config.disk_iops
            throughput            = ng_config.disk_throughput
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Environment-specific configuration
      ami_type                   = ng_config.ami_type
      capacity_type             = ng_config.capacity_type
      disable_api_termination   = var.environment == "prod" ? true : false

      # Scaling configuration based on environment
      update_config = {
        max_unavailable_percentage = var.environment == "prod" ? 10 : 25
      }

      # User data for node customization
      user_data_template_path = ng_config.user_data_template_path

      tags = merge(var.common_tags, {
        NodeGroup = ng_name
        Environment = var.environment
      })
    }
  }
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = var.addon_versions.vpc_cni
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = null

  depends_on = [module.eks]
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = var.addon_versions.coredns
  resolve_conflicts = "OVERWRITE"

  depends_on = [module.eks]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.addon_versions.kube_proxy
  resolve_conflicts = "OVERWRITE"

  depends_on = [module.eks]
}

# EBS CSI Driver with IRSA
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.common_tags
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_versions.ebs_csi
  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn

  depends_on = [module.eks]
}