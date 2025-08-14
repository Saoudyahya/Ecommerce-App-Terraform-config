# environments/dev/terraform.tfvars - Optimized for small instances

# Basic Configuration
aws_region      = "us-east-1"
project_name    = "nexus-commerce"
owner           = "Platform Team"
cost_center     = "Engineering"
kubernetes_version = "1.28"

# Network Configuration - Simplified
vpc_cidr = "10.0.0.0/16"
private_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
public_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]

# Cost-optimized networking
enable_nat_gateway = true
number_of_azs     = 2  # Only 2 AZs to reduce costs

# MINIMAL Node Group Configuration
node_groups = {
  general = {
    instance_types      = ["t2.micro"]  # Free tier eligible
    min_size           = 1
    max_size           = 2
    desired_size       = 1
    disk_size          = 20
    disk_type          = "gp2"          # Free tier eligible
    disk_iops          = 100            # Default for gp2
    disk_throughput    = 125
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"
    user_data_template_path = null
    labels = {
      "node-type" = "general"
    }
    taints = null
  }
}

# EKS Admin Users - Add your IAM users here
eks_admin_users = []
aws_auth_roles = []

# EKS Addon Versions - Using older, more stable versions
addon_versions = {
  vpc_cni    = "v1.14.1-eksbuild.1"    # Older, more stable
  coredns    = "v1.10.1-eksbuild.2"    # Older version
  kube_proxy = "v1.28.1-eksbuild.1"    # Older version
  ebs_csi    = "v1.23.0-eksbuild.1"    # Older, more stable
}

# ArgoCD Configuration - DISABLED for now
argocd_version = "5.46.8"
bootstrap_argocd     = false  # Disable to reduce resource usage initially
gitops_repo_url      = "https://github.com/ZakariaRek/gitops-repo_ArgoCD"
gitops_repo_branch   = "develop"
gitops_repo_path     = "argocd/applications"
auto_sync_prune      = true
auto_sync_self_heal  = true
use_custom_project   = false

# Minimal Features
enable_monitoring        = false
enable_external_dns     = false
domain_name             = ""

# Minimal Security Groups
additional_security_groups = []