# modules/eks-cluster/main.tf
# Simplified version for free tier without duplicate node groups

# Data sources
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EKS Cluster (without managed node groups)
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                          = var.vpc_id
  subnet_ids                      = var.private_subnet_ids
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  cluster_enabled_log_types = var.cluster_enabled_log_types

  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  # Don't create any managed node groups through the module
  eks_managed_node_groups = {}

  # Disable automatic aws-auth management to avoid conflicts
  manage_aws_auth_configmap = false

  tags = merge(var.common_tags, var.cluster_tags)
}

# Create IAM roles for node groups
resource "aws_iam_role" "node_group_role" {
  for_each = var.node_groups

  name = "${var.cluster_name}-${each.key}-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${each.key}-node-group-role"
  })
}

# Attach required policies to node group roles
resource "aws_iam_role_policy_attachment" "node_group_worker_node_policy" {
  for_each = var.node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  for_each = var.node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  for_each = var.node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role[each.key].name
}

# Create managed node groups manually (simplified version)
resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_name    = module.eks.cluster_name
  node_group_name = "${each.key}-nodes"
  node_role_arn   = aws_iam_role.node_group_role[each.key].arn
  subnet_ids      = var.private_subnet_ids

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = var.environment == "prod" ? 10 : 25
  }

  # Instance configuration
  instance_types = each.value.instance_types
  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  # Labels
  labels = merge(
    {
      role = each.key
      "node.kubernetes.io/node-type" = each.key
    },
      each.value.labels != null ? each.value.labels : {}
  )

  # Taints
  dynamic "taint" {
    for_each = each.value.taints != null ? each.value.taints : {}
    iterator = taint_config
    content {
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  tags = merge(var.common_tags, {
    NodeGroup   = each.key
    Environment = var.environment
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_node_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy,
    module.eks
  ]
}

# Create aws-auth ConfigMap manually to include our node groups
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      # Add our node group roles
      [
        for ng_name, ng_role in aws_iam_role.node_group_role : {
        rolearn  = ng_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
      ],
      # Add any additional IAM roles
      var.aws_auth_roles
    ))

    mapUsers = yamlencode(var.eks_admin_users)
  }

  depends_on = [
    module.eks,
    aws_iam_role.node_group_role
  ]
}

# EBS CSI Driver IRSA Role
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

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "vpc-cni"
  addon_version     = var.addon_versions.vpc_cni
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_node_group.node_groups]
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = var.addon_versions.coredns
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.node_groups,
    aws_eks_addon.vpc_cni
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.addon_versions.kube_proxy
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_node_group.node_groups]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_versions.ebs_csi
  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.node_groups,
    module.ebs_csi_irsa_role
  ]
}