# modules/eks-cluster/outputs.tf
# Updated outputs for the bypassed EKS module

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

# Updated to use our manually created node groups
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value = merge(
    # Standard node groups
    {
      for ng_name, ng in aws_eks_node_group.node_groups : ng_name => {
      arn           = ng.arn
      cluster_name  = ng.cluster_name
      node_group_name = ng.node_group_name
      status        = ng.status
      capacity_type = ng.capacity_type
      instance_types = ng.instance_types
      scaling_config = ng.scaling_config
      labels        = ng.labels
      taints        = ng.taint
    }
    },
    # Node groups with launch templates
    {
      for ng_name, ng in aws_eks_node_group.node_groups_with_lt : "${ng_name}-lt" => {
      arn           = ng.arn
      cluster_name  = ng.cluster_name
      node_group_name = ng.node_group_name
      status        = ng.status
      capacity_type = ng.capacity_type
      instance_types = ng.instance_types
      scaling_config = ng.scaling_config
      labels        = ng.labels
      taints        = ng.taint
      launch_template = ng.launch_template
    }
    }
  )
  sensitive = true
}

output "node_group_roles" {
  description = "IAM role ARNs for node groups"
  value = {
    for ng_name, role in aws_iam_role.node_group_role : ng_name => role.arn
  }
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = module.ebs_csi_irsa_role.iam_role_arn
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks.cluster_name}"
}

# Additional outputs for use by other modules
output "cluster_primary_security_group_id" {
  description = "Primary security group ID of the EKS cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS node groups"
  value       = module.eks.node_security_group_id
}

# EKS Addons outputs
output "cluster_addons" {
  description = "Map of cluster addon attributes"
  value = {
    vpc_cni    = aws_eks_addon.vpc_cni
    coredns    = aws_eks_addon.coredns
    kube_proxy = aws_eks_addon.kube_proxy
    ebs_csi    = aws_eks_addon.ebs_csi
  }
}

# Launch template information
output "launch_templates" {
  description = "Launch templates created for node groups"
  value = {
    for ng_name, lt in aws_launch_template.node_group_lt : ng_name => {
      id           = lt.id
      latest_version = lt.latest_version
      name         = lt.name
    }
  }
}