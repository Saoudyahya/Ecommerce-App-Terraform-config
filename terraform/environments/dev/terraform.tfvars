# environments/dev/terraform.tfvars - Improved for EKS stability

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
number_of_azs     = 2

# IMPROVED Node Group Configuration
node_groups = {
  general = {
    instance_types      = ["t3.small"]  # Minimum recommended for EKS
    min_size           = 1
    max_size           = 3
    desired_size       = 2              # 2 nodes for better stability
    disk_size          = 30             # Increased for system pods
    disk_type          = "gp3"
    disk_iops          = 3000
    disk_throughput    = 125
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"    # Stable for system components
    user_data_template_path = null
    labels = {
      "node-type" = "general"
    }
    taints = null
  }
}

# EKS Admin Users
eks_admin_users = []
aws_auth_roles = []

# COMPATIBLE EKS Addon Versions for 1.28
addon_versions = {
  vpc_cni    = "v1.15.1-eksbuild.1"
  coredns    = "v1.10.1-eksbuild.5"
  kube_proxy = "v1.28.2-eksbuild.2"
  ebs_csi    = "v1.24.0-eksbuild.1"
}

# ArgoCD Configuration - Start disabled
argocd_version = "5.46.8"
bootstrap_argocd     = false
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