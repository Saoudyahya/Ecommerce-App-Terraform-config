# modules/eks-cluster/main.tf
# Complete bypass of the EKS module's managed node groups to avoid for_each issues

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

  # CRITICAL: Don't create any managed node groups through the module
  eks_managed_node_groups = {}

  # ConfigMap management - let Terraform handle it properly
  manage_aws_auth_configmap = true
  create_aws_auth_configmap = true  # This will create the ConfigMap if it doesn't exist

  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.eks_admin_users

  tags = merge(var.common_tags, var.cluster_tags)
}

# Create managed node groups manually to avoid the for_each issue
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

# Launch template for advanced configuration (optional)
resource "aws_launch_template" "node_group_lt" {
  for_each = {
    for ng_name, ng_config in var.node_groups : ng_name => ng_config
    if ng_config.disk_type == "gp3" || ng_config.user_data_template_path != null
  }

  name_prefix = "${var.cluster_name}-${each.key}-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.disk_size
      volume_type           = each.value.disk_type
      iops                  = each.value.disk_iops
      throughput            = each.value.disk_throughput
      encrypted             = true
      delete_on_termination = true
    }
  }

  # User data if provided
  user_data = each.value.user_data_template_path != null && each.value.user_data_template_path != "" ? base64encode(file(each.value.user_data_template_path)) : null

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name        = "${var.cluster_name}-${each.key}-node"
      NodeGroup   = each.key
      Environment = var.environment
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${each.key}-launch-template"
  })
}

# Update node groups to use launch templates if they exist
resource "aws_eks_node_group" "node_groups_with_lt" {
  for_each = {
    for ng_name, ng_config in var.node_groups : ng_name => ng_config
    if ng_config.disk_type == "gp3" || ng_config.user_data_template_path != null
  }

  cluster_name    = module.eks.cluster_name
  node_group_name = "${each.key}-nodes-lt"
  node_role_arn   = aws_iam_role.node_group_role[each.key].arn
  subnet_ids      = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.node_group_lt[each.key].id
    version = aws_launch_template.node_group_lt[each.key].latest_version
  }

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
    aws_launch_template.node_group_lt,
    module.eks
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

  depends_on = [
    aws_eks_node_group.node_groups,
    aws_eks_node_group.node_groups_with_lt
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = var.addon_versions.coredns
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.node_groups,
    aws_eks_node_group.node_groups_with_lt,
    aws_eks_addon.vpc_cni
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.addon_versions.kube_proxy
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.node_groups,
    aws_eks_node_group.node_groups_with_lt
  ]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_versions.ebs_csi
  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.node_groups,
    aws_eks_node_group.node_groups_with_lt,
    module.ebs_csi_irsa_role
  ]
}