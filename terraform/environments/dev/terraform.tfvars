# environments/dev/terraform.tfvars

# Basic Configuration
aws_region      = "us-east-1"
project_name    = "nexus-commerce"
owner           = "Platform Team"
cost_center     = "Engineering"
kubernetes_version = "1.28"

# Network Configuration - Dev Environment
vpc_cidr = "10.0.0.0/16"
private_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]
public_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24",
  "10.0.103.0/24"
]

# Networking settings for dev (cost-optimized)
enable_nat_gateway = true
number_of_azs     = 2  # Only 2 AZs for dev to reduce costs

# Node Group Configuration - Development
node_groups = {
  system = {
    instance_types      = ["t3.medium"]  # Smaller instances for dev
    min_size           = 1
    max_size           = 3
    desired_size       = 1
    disk_size          = 30
    disk_type          = "gp3"
    disk_iops          = 3000
    disk_throughput    = 125
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"
    user_data_template_path = null
    labels = {
      "node-type" = "system"
    }
    taints = {
      dedicated = {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }

  applications = {
    instance_types      = ["t3.large"]  # Smaller for dev workloads
    min_size           = 1
    max_size           = 5
    desired_size       = 2
    disk_size          = 50
    disk_type          = "gp3"
    disk_iops          = 3000
    disk_throughput    = 125
    ami_type           = "AL2_x86_64"
    capacity_type      = "SPOT"  # Use spot instances for cost savings in dev
    user_data_template_path = null
    labels = {
      "node-type" = "applications"
    }
    taints = null
  }

  data = {
    instance_types      = ["r5.large"]  # Smaller memory-optimized for dev
    min_size           = 0  # Can scale to zero in dev
    max_size           = 3
    desired_size       = 1
    disk_size          = 100
    disk_type          = "gp3"
    disk_iops          = 3000
    disk_throughput    = 125
    ami_type           = "AL2_x86_64"
    capacity_type      = "SPOT"  # Use spot for data nodes in dev
    user_data_template_path = null
    labels = {
      "node-type" = "data"
    }
    taints = null
  }
}

# EKS Admin Users - Add your IAM users here
eks_admin_users = [
  # Example:
  # {
  #   userarn  = "arn:aws:iam::388762879261:user/your-dev-user"
  #   username = "your-dev-user"
  #   groups   = ["system:masters"]
  # }
]

aws_auth_roles = []

# EKS Addon Versions
addon_versions = {
  vpc_cni    = "v1.15.1-eksbuild.1"
  coredns    = "v1.10.1-eksbuild.5"
  kube_proxy = "v1.28.2-eksbuild.2"
  ebs_csi    = "v1.24.0-eksbuild.1"
}

# ArgoCD Configuration
argocd_version = "5.46.8"

# ArgoCD Bootstrap Configuration
bootstrap_argocd     = true
gitops_repo_url      = "https://github.com/ZakariaRek/gitops-repo_ArgoCD"
gitops_repo_branch   = "develop"  # Use develop branch for dev environment
gitops_repo_path     = "argocd/applications"
auto_sync_prune      = true
auto_sync_self_heal  = true
use_custom_project   = false

# Optional Features - Development
enable_monitoring        = false  # Disabled to save costs
enable_external_dns     = false
domain_name             = ""

# Security Groups
additional_security_groups = [
  {
    name        = "dev-additional"
    description = "Additional security group for development"
    ingress_rules = [
      {
        description = "HTTP from anywhere (dev only)"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "HTTPS from anywhere"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    egress_rules = [
      {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
]